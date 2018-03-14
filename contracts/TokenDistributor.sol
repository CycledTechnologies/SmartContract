pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CycledToken.sol";
import "./Whitelist.sol";


contract TokenDistributor is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CycledToken private token;

    // The token being sold
    Whitelist private whitelist;

    // Total Token Sold
    uint256 public tokenSold;

    // Total Token Sold in preSale
    uint256 public preSaletokenSold;

    address tokenWallet;
    
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
    uint8 public issueIndex = 0;


    /// pre-sale start time; Is equivalent to: 01/05/2018 @ 12:00am (UTC) ; Round 1
    uint64 private constant date01May2018 = 1525132800;

    /// pre-sale end time; Is equivalent to: 28/05/2018 @ 11:59pm (UTC)  ; Round 1
    uint64 private constant date28May2018 = 1527551940;

    /// main-sale start time; Is equivalent to: 13/08/2018 @ 12:00am (UTC) ; Round 2
    uint64 private constant date13Aug2018 = 1534118400;

    /// main-sale end time; Is equivalent to: 07/09/2018 @ 11:59pm (UTC)  ; Round 2
    uint64 private constant date7Sep2018 = 1536364740;


    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    /**
    * @dev Reverts if not in crowdsale time range. 
    */
    modifier onlyWhileOpen {
        require( (now >= date01May2018 && now <= date28May2018) || 
                    (now >= date13Aug2018 && now <= date7Sep2018) );
        _;
    }

    function TokenDistributor(address _tokenAddress, address _whitelistAddress) public {
        require(_tokenAddress != address(0));
        tokenWallet = msg.sender;
        token = CycledToken(_tokenAddress);
        whitelist = Whitelist(_whitelistAddress);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

        
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(whitelist.isWhitelisted(_beneficiary));
        uint256 weiAmount = msg.value;
        doIssueTokens(_beneficiary, weiAmount);
        owner.transfer(weiAmount);
    }

    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public onlyOwner onlyWhileOpen {
       doIssueTokens(_beneficiary, _investedWieAmount);
    }

    
    /* 
    * @dev Determine the current sale round.
    * @return current sale round by date.
    */
    function currentSale() internal view onlyWhileOpen returns (uint8) {
        uint8 roundNum = 0;
        if (now >= date01May2018 && now <= date28May2018) 
            roundNum = 1;// Pre-Sale round
        else if (now >= date13Aug2018 && now <= date7Sep2018) 
            roundNum = 2;// Main-Sale round
     
        return roundNum;
    }


    /* 
    * @dev issue tokens
    * @param _beneficiary address that the tokens will be sent to.
    * @param _investedWieAmount amount to invest
    */
    function doIssueTokens(address _beneficiary, uint256 _investedWieAmount) internal onlyWhileOpen {

        require(_beneficiary != address(0));
        require(_investedWieAmount != 0);

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
        Issue(issueIndex++, _beneficiary, tokens);

    }

   /*
    * @param _weiAmount Ether amount from that the token price to be calculated with including discount
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

    function forwardFunds() onlyOwner public {
        address thisAddress = this;
        owner.transfer(thisAddress.balance);
  }
}