pragma solidity 0.4.19;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CycledToken.sol";
import "./Whitelist.sol";


contract CycledCrowdsale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CycledToken private token;

    // whitelist contract 
    Whitelist private whitelist;

    // Total Token Sold
    uint256 public tokenSold;

    address private tokenWallet;

    address private fundWallet;
    
    // USe to set the base rate
    uint256 private BASE_RATE = 25000;

    //pre sale cap
    uint256 public PRE_SALE_HARD_CAP = 200000000 * 10**uint256(DECIMAL);
    
    //main sale cap
    uint256 public MAIN_SALE_HARD_CAP = 300000000 * 10**uint256(DECIMAL);

    // Total Wei raised
    uint256 public weiRaised = 0;

    uint8 private constant DECIMAL = 18;

    /// Issue event index starting from 0.
    uint64 public issuedIndex = 0;


    /// pre-sale start time; Is equivalent to: Tue, 01 May 2018 @ 1:00pm (UTC) ; Round 1
    uint64 private constant date01May2018 = 1525179600;

    /// pre-sale end time; Is equivalent to: Thu, 31 May 2018 @ 11:59pm (UTC) ; Round 1
    uint64 private constant date31May2018 = 1527811140;

    /// main-sale start time; Is equivalent to: Mon, 13 Aug 2018 @ 1:00pm (UTC) ; Round 2
    uint64 private constant date13Aug2018 = 1534165200;

    /// main-sale end time; Is equivalent to: Fri, 07 Sep 2018 @ 11:59pm (UTC)  ; Round 2
    uint64 private constant date7Sep2018 = 1536364740;


    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    /**
    * @dev Reverts if not in crowdsale time range. 
    */
    modifier onlyWhileOpen {
        uint64 _now = uint64(block.timestamp);
        require( (_now >= date01May2018 && _now <= date31May2018) || 
                    (_now >= date13Aug2018 && _now <= date7Sep2018) );
        _;
    }

    function CycledCrowdsale(address _tokenAddress, address _whitelistAddress, address _fundWallet) public {
        require(_tokenAddress != address(0));
        require(_whitelistAddress != address(0));
        require(_fundWallet != address(0));
        tokenWallet = msg.sender;
        fundWallet = _fundWallet;
        token = CycledToken(_tokenAddress);
        whitelist = Whitelist(_whitelistAddress);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev Validation of an incoming purchase. 
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value involved in the purchase
    */
    function preValidateInvestment(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount >= 0.05 ether);
    }

    /* 
    * @dev (fallback)tranfer tokens to beneficiary as per its investment.
    * @param _beneficiary to which token must transfer
    */
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        preValidateInvestment(_beneficiary, weiAmount);
        require(whitelist.isWhitelisted(_beneficiary));
        doIssueTokens(_beneficiary, weiAmount);
        fundWallet.transfer(weiAmount);
    }

        
    /* 
    * @dev tranfer tokens to beneficiary as per its investment.
    * @param _beneficiary to which tranfer token
    * @param _investedWieAmount investment amount by the beneficiary
    */
    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public onlyOwner onlyWhileOpen {
       doIssueTokens(_beneficiary, _investedWieAmount);
    }

    
    /* 
    * @dev Determine the current sale round.
    * @return current sale round by date.
    */
    function currentSale() internal view onlyWhileOpen returns (uint8) {
        uint8 roundNum = 0;
        uint64 _now = uint64(block.timestamp);
        if (_now >= date01May2018 && _now <= date31May2018) 
            roundNum = 1;// Pre-Sale round
        else if (_now >= date13Aug2018 && _now <= date7Sep2018) 
            roundNum = 2;// Main-Sale round
     
        return roundNum;
    }

    /* 
    * @dev issue tokens
    * @param _beneficiary address that the tokens will be sent to.
    * @param _investedWieAmount amount to invest
    */
    function doIssueTokens(address _beneficiary, uint256 _investedWieAmount) internal onlyWhileOpen {

        preValidateInvestment(_beneficiary, _investedWieAmount);

        //Compute number of tokens to transfer
        uint256 tokens = getTokenAfterDiscount(_investedWieAmount, tokenSold);
        
        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);
        uint8 curSaleRound = currentSale();

        //Checking if presale is running or mainsale
        if (curSaleRound == 1) {
            require(increasedtokenSold <= PRE_SALE_HARD_CAP);
        } else {
            require(increasedtokenSold <= MAIN_SALE_HARD_CAP.add(PRE_SALE_HARD_CAP)); 
        }
        
        // increase token total supply
        tokenSold = increasedtokenSold;
        //increase wie raised
        weiRaised = weiRaised.add(_investedWieAmount);

        token.transferFrom(tokenWallet, _beneficiary, tokens);

        // event is fired when tokens issued
        Issue(issuedIndex++, _beneficiary, tokens);

    }

   /*
    * @param _weiAmount Ether amount from that the token price to be calculated with including discount
    * @param _totalTokenSold Total token sold so far
    * @return token amount after applying the discount
    */
    function getTokenAfterDiscount(uint256 _weiAmount, uint256 _totalTokenSold) public view returns (uint256) {
        
        uint256 round = currentSale();        
        uint256 maxTokenForMaxDiscount = (75000000 * 10**uint256(18));
        
        // No discount
        if (round == 2) {
            return _weiAmount.mul(BASE_RATE);
        } 
        // Pre-Sale discount
        else if (round == 1) {
            if(_totalTokenSold >= maxTokenForMaxDiscount) {
                return _weiAmount.mul(BASE_RATE).mul(100).div(70);
            } else {
                uint256 maxDiscountedTokens = maxTokenForMaxDiscount.sub(_totalTokenSold);
                if (maxDiscountedTokens >= _weiAmount.mul(BASE_RATE).mul(100).div(50)) {
                    return _weiAmount.mul(BASE_RATE).mul(100).div(50);
                } else{
                    uint256 maxDiscounteTokenPrice = maxDiscountedTokens.mul(50).div(BASE_RATE.mul(100));
                    return maxDiscountedTokens.add((_weiAmount.sub(maxDiscounteTokenPrice)).mul(BASE_RATE).mul(100).div(70));
                }
            }
        } 
        return 0;
    }

    /*
    * @dev forward funds to fundwallet if any stuck in contract 
    */
    function forwardFunds() onlyOwner public {
        address thisAddress = this;
        fundWallet.transfer(thisAddress.balance);
    }


}