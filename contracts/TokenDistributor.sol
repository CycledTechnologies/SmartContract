pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CycledToken.sol";


contract TokenDistributor is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CycledToken private token;
    
    // USe to set the base rate
    uint256 private baseRate = 25000;

    // Total Token Sold
    uint256 public tokenSold;

    // Total Token Sold in preSale
    uint256 public preSaletokenSold;

    // Total Wei raised
    uint256 public weiRaised = 0;

    uint8 private constant DECIMAL = 18;
    
    //pre sale cap
    uint256 public preSaleHardCap = 200000000 * 10**uint256(DECIMAL);
    
    //main sale cap
    uint256 public mainSaleHardCap = 300000000 * 10**uint256(DECIMAL);

    /// is pre-sale is running or not
    bool public preSaleRunning = false;

    /// is main-sale is running or not
    bool public mainSaleRunning = false;

    /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    /// presale wallet address 
    address private preSaleWallet;

    /// mainsale wallet address
    address private mainSaleWallet;

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

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

    function TokenDistributor(
        address _tokenAddress, 
        address _preSaleWallet,
        address _mainSaleWallet) public {

        require(_tokenAddress != address(0));
        require(_preSaleWallet != address(0));
        require(_mainSaleWallet != address(0));

        preSaleWallet = _preSaleWallet;
        mainSaleWallet = _mainSaleWallet;
        token = CycledToken(_tokenAddress);
    }
    

    /* 
    * @dev issue tokens to a single buyer
    * @param _beneficiary address that the tokens will be sent to.
    * @param _investedWieAmount amount to invest
    */
    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public onlyOwner beforeEnd {

        require(_beneficiary != address(0));
        require(_investedWieAmount != 0);
        require(preSaleRunning || mainSaleRunning);
        address wallet;
        //Compute number of tokens to transfer
        uint256 tokens = getTokenAfterDiscount(_investedWieAmount);
        
        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);
         
        //Checking if presale is running or mainsale
        if (preSaleRunning) {
            wallet = preSaleWallet;
            require(increasedtokenSold <= preSaleHardCap);
        } else {
            wallet = mainSaleWallet;
            require(increasedtokenSold <= mainSaleHardCap); 
        }
        
        // increase token total supply
        tokenSold = increasedtokenSold;
        //increase wie raised
        weiRaised = weiRaised.add(_investedWieAmount);

        token.transferFrom(wallet, _beneficiary, tokens);

        // event is fired when tokens issued
        Issue(issueIndex++, _beneficiary, tokens);

    }

    /* 
    * @dev check if msg sender is allowed to access method. 
    */
    function isMsgSenderAllowed() internal view {
        if (preSaleRunning)
            require(msg.sender == preSaleWallet);
        else
            require(msg.sender == mainSaleWallet);
    }

    /* 
    *  @dev Start pre-sale. 
    */
    function startPreSale() public onlyOwner beforeEnd noActiveSale {
        preSaleRunning = true;
    }

    /* 
    *  @dev Start main-sale. 
    */
    function startMainSale() public onlyOwner beforeEnd noActiveSale {
        mainSaleRunning = true;
    }

    /* 
    *  @dev end pre-sale. 
    */
    function endPreSale() public onlyOwner beforeEnd {
        require(preSaleRunning);

        preSaleRunning = false;

        ///setting presale tokensold
        preSaletokenSold = tokenSold;

        ///tranfer remaining tokens to mainsale wallet
        token.transferFrom(preSaleWallet, mainSaleWallet, preSaleHardCap.sub(tokenSold));

        ///Incresing hardcap of mainsale
        mainSaleHardCap = mainSaleHardCap.add(preSaleHardCap.sub(tokenSold));
    }
    
    /* 
    *  @dev end main-sale.
    */
    function endMainSale() public onlyOwner beforeEnd {
        require(mainSaleRunning);
        mainSaleRunning = false;
    }

    /* 
    * @dev close the sale
    */
    function close() public onlyOwner beforeEnd {
        tokenSaleClosed = true;
    }

    /*
    * @param _weiAmount Ether amount from that the token price to be calculated with including discount
    * @return token amount after applying the discount
    */
    function getTokenAfterDiscount(uint256 _weiAmount) public view returns (uint256) {
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