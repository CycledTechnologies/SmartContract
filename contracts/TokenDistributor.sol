pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CycledToken.sol";


contract TokenDistributor is Ownable {
    using SafeMath for uint256;

    struct Transfer {
        uint256 tokens;
        bool transfered;
    }
    mapping(address => Transfer) assignedTokens;

    address[] addresses;

    // The token being sold
    CycledToken private token;

    // USe to set the base rate
    uint256 private baseRate;

    // Total Token Sold
    uint256 public tokenSold;

    // Total Wei raised
    uint256 public weiRaised = 0;

    
    uint8 private constant DECIMAL = 18;

    /// no tokens can be ever issued when this is set to "true"
    bool public preSaleRunning = false;

    /// no tokens can be ever issued when this is set to "true"
    bool public mainSaleRunning = false;

     /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    address private preSaleWallet;

    address private mainSaleWallet;

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    /// Emitted for each sucuessful token assigned.
    event TokenAssigned(address addr, uint256 tokenAmount);

    /// Allow the closing to happen only once
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    /// NO Sale is active
    modifier noActiveSale {
         require(!preSaleRunning && !mainSaleRunning);
        _;
    }

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _tokenAddress of the token being sold
    */
    function TokenDistributor(
        uint256 _rate, 
        address _tokenAddress, 
        address _preSaleWallet,
        address _mainSaleWallet) public {

        require(_rate > 0);
        require(_tokenAddress != address(0));

        baseRate = _rate;
        preSaleWallet = _preSaleWallet;
        mainSaleWallet = _mainSaleWallet;
        token = CycledToken(_tokenAddress);
    }

    /// @dev Issue tokens for a single buyer on the presale
    /// @param _beneficiary addresses that the presale tokens will be sent to.
    /// @param _investedWieAmount the amount to invest, with decimals expanded (full).
    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public beforeEnd {
        require(_beneficiary != address(0));
        require(_investedWieAmount != 0);
        require(preSaleRunning || mainSaleRunning);
        isMsgSenderAllowed();
           
        //Compute number of tokens to transfer
        uint256 tokens = getTokenAmount(_investedWieAmount);

        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);

        // increase token total supply
        tokenSold = increasedtokenSold;
        //increase wie raised
        weiRaised = weiRaised.add(_investedWieAmount);

        //Assign the tokens to the _beneficiary
        Transfer storage aT = assignedTokens[_beneficiary];
        aT.tokens = tokens;
        aT.transfered = false;
        addresses.push(_beneficiary);
        // event is fired when tokens assigned
        TokenAssigned(_beneficiary, tokens);
    }

    function isMsgSenderAllowed() internal view {
        if (preSaleRunning)
            require(msg.sender == preSaleWallet);
        else
            require(msg.sender == mainSaleWallet);
    }


    function dispatchTokens() public beforeEnd {
        isMsgSenderAllowed();
        require(issueIndex < addresses.length);
        for (uint index = issueIndex; index < addresses.length; index++) {
            if (!assignedTokens[addresses[index]].transfered) {
                token.transferFrom(msg.sender, addresses[index], assignedTokens[addresses[index]].tokens);
                assignedTokens[addresses[index]].transfered = true;
                Issue(issueIndex++, addresses[index], assignedTokens[addresses[index]].tokens);
            }
        }
    }
    
    /// @dev Compute the amount of token that can be purchased.
    /// @param _weiAmount Amount of Ether to purchase CYD.
    /// @return Amount of token to purchase
    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = _weiAmount.mul(baseRate);
        uint8 discount = getDiscount();
        tokens = tokenBase.mul(discount).div(100).add(tokenBase);
    }

    /// @dev Compute the discount.
    /// @return discount percentage
    function getDiscount() internal view returns (uint8) {
        uint256 _tokenSold = tokenSold * 10**uint256(DECIMAL);
        uint256 _amountFor30perDiscount = 75000000 * 10**uint256(DECIMAL);
        if (_tokenSold >= _amountFor30perDiscount && preSaleRunning) 
            return 30;
        if (_tokenSold < _amountFor30perDiscount && preSaleRunning) 
            return 50;
        return 0;
    }

    /// @dev Start the pre-sale.
    function startPreSale() public onlyOwner beforeEnd noActiveSale {
        preSaleRunning = true;
    }

    /// @dev Start the main-sale.
    function startMainSale() public onlyOwner beforeEnd noActiveSale {
        mainSaleRunning = true;
    }

    /// @dev Start the main-sale.
    function endPreSale() public onlyOwner beforeEnd {
        require(preSaleRunning);
        preSaleRunning = false;
    }

    /// @dev end the main-sale.
    function endMainSale() public onlyOwner beforeEnd {
        require(mainSaleRunning);
        mainSaleRunning = false;
    }

    /// @dev close the sale
    function close() public onlyOwner beforeEnd {
        tokenSaleClosed = true;
    }

}