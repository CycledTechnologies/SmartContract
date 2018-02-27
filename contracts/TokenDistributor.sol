pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CycledToken.sol";

contract TokenDistributor is Ownable {
    using SafeMath for uint256;

    struct Transfer {
        uint256 amount;
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
    function TokenDistributor(uint256 _rate, address _tokenAddress) public {
        require(_rate > 0);
        require(_tokenAddress != address(0));

        baseRate = _rate;
        token = CycledToken(_tokenAddress);
    }

    /// @dev Issue tokens for a single buyer on the presale
    /// @param _beneficiary addresses that the presale tokens will be sent to.
    /// @param _investedWieAmount the amount to invest, with decimals expanded (full).
    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public onlyOwner beforeEnd {
        require(_beneficiary != address(0));
        require(_investedWieAmount != 0);
        require(preSaleRunning || mainSaleRunning);

        //Compute number of tokens to transfer
        uint256 tokens = getTokenAmount(_investedWieAmount);

        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);

        // increase token total supply
        tokenSold = increasedtokenSold;
        //increase wie raised
        weiRaised = weiRaised.add(_investedWieAmount);

        //Transfering tokens from issue token wallet to beneficiary wallet
        //token.transferFrom(owner, _beneficiary, tokens);

        Transfer storage aT = assignedTokens[_beneficiary];
        aT.amount = tokens;
        aT.transfered = false;
        addresses.push(_beneficiary);
        TokenAssigned(_beneficiary, tokens);

        // event is fired when tokens issued
    }


    function dispatchTokens() public onlyOwner beforeEnd {
        require(issueIndex < addresses.length);
        for (uint index = issueIndex; index < addresses.length; index++) {
            if (!assignedTokens[addresses[index]].transfered) {
                token.transferFrom(owner, addresses[index], assignedTokens[addresses[index]].amount);
                assignedTokens[addresses[index]].transfered = true;
                Issue(issueIndex++, addresses[index], assignedTokens[addresses[index]].amount);
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

    function getTokenAfterDiscount(uint256 _token, uint256 _tokenSold) internal view returns (uint256) {
        uint256 fiftyPerDiscountedToken = 0;
        uint256 thirtyPerDiscountedToken = 0;
        
        uint256 maxTokenForMaxDiscount = (75000000 * 10**uint256(18));
        
        if (_tokenSold >= maxTokenForMaxDiscount) {
            //Apply 30% discount
            fiftyPerDiscountedToken = 0;
            thirtyPerDiscountedToken = _token;
        }
        else {
            uint256 tokenSoldAfterCurrentToken = _tokenSold.add(_token);
            if (tokenSoldAfterCurrentToken > maxTokenForMaxDiscount) {
                //Calculate partial Tokens for 50% and 30% discount
                uint256 remainingMaxTokenForMaxDiscount = maxTokenForMaxDiscount.sub(_tokenSold);
                uint256 difference = 0;
                if (remainingMaxTokenForMaxDiscount > _token) {
                    difference = remainingMaxTokenForMaxDiscount.sub(_token);
                }
                else {
                    difference = _token.sub(remainingMaxTokenForMaxDiscount);
                }
                fiftyPerDiscountedToken = _token.sub(difference);
                thirtyPerDiscountedToken = _token.sub(fiftyPerDiscountedToken);
            } 
            else {
                //Apply 50% discount
                fiftyPerDiscountedToken = _token;
                thirtyPerDiscountedToken = 0;
            }
        }
        return _token.add(fiftyPerDiscountedToken.mul(50).div(100) + thirtyPerDiscountedToken.mul(30).div(100));
    } 

}