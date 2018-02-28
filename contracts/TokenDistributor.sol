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

    // Total Token Sold in preSale
    uint256 public preSaletokenSold;

    // Total Wei raised
    uint256 public weiRaised = 0;

    
    uint8 private constant DECIMAL = 18;
    
    // Set the max limit for pre sale cap
    uint256 preSaleHardCap = 200000000 * 10**uint256(DECIMAL);
    
    //Set the min limit of main sale cap
    uint256 mainSaleHardCap = 300000000 * 10**uint256(DECIMAL);

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
    
    /*
    * @param _token the token that needs to be validated against what has been distributed and the tokens are in max cap
    */
    function validateTransfer(uint256 _token) internal view {
        if (preSaleRunning) {
            require(_token <= preSaleHardCap);
        } else {
            require(_token <= (mainSaleHardCap + preSaleHardCap.sub(preSaletokenSold))); 
        }
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
        uint256 tokens = getTokenAfterDiscount(_investedWieAmount);
        
        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);
         
        validateTransfer(increasedtokenSold);
        
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
        preSaletokenSold = tokenSold;
        token.transferFrom(preSaleWallet, mainSaleWallet, preSaleHardCap.sub(tokenSold));
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

    /*
    * @param _weiAmount Ether amount from that the token price to be calculated with including discount
    * @dev returns token amount after applying the discount in pre sale
    */
    function getTokenAfterDiscount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 fiftyPerDiscountedToken = 0;
        uint256 thirtyPerDiscountedToken = 0;
        uint256 _token = _weiAmount.mul(baseRate);

        uint256 maxTokenForMaxDiscount = (75000000 * 10**uint256(18));
        
        if (!preSaleRunning) {
            fiftyPerDiscountedToken = 0;
            thirtyPerDiscountedToken = 0;
        } else if (tokenSold >= maxTokenForMaxDiscount) {
            //Apply 30% discount
            fiftyPerDiscountedToken = 0;
            thirtyPerDiscountedToken = _token;
        } else {
            uint256 tokenSoldAfterCurrentToken = tokenSold.add(_token);
            if (tokenSoldAfterCurrentToken > maxTokenForMaxDiscount) {
                //Calculate partial Tokens for 50% and 30% discount
                uint256 remainingMaxTokenForMaxDiscount = maxTokenForMaxDiscount.sub(tokenSold);
                uint256 difference = 0;
                if (remainingMaxTokenForMaxDiscount > _token) {
                    difference = remainingMaxTokenForMaxDiscount.sub(_token);
                } else {
                    difference = _token.sub(remainingMaxTokenForMaxDiscount);
                }
                fiftyPerDiscountedToken = _token.sub(difference);
                thirtyPerDiscountedToken = _token.sub(fiftyPerDiscountedToken);
            } else {
                //Apply 50% discount
                fiftyPerDiscountedToken = _token;
                thirtyPerDiscountedToken = 0;
            }
        }
        return _token.add((fiftyPerDiscountedToken.mul(50).div(100).add(thirtyPerDiscountedToken.mul(30).div(100))));
    }
}