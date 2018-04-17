pragma solidity 0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}












/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    /**
    * @param _wallet Vault address
    */
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    /**
    * @param investor Investor address
    */
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    /**
    * @param investor Investor address
    */
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}




/**
 * @title RefundableCrowdsaled
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract RefundableCrowdsale is Ownable {
    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 public goal;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    //
    uint64 closingTime;

     // Total Wei raised
    uint256 public weiRaised;

    bool public isFinalized = false;

    event Finalized();

    /**
    * @dev Constructor, creates RefundVault. 
    * @param _goal Funding goal
    * @param _wallet Refund Vault
    * @param _closingTime closing time of first sale
    */
    function RefundableCrowdsale(uint256 _goal, address _wallet, uint64 _closingTime) public {
        require(_goal > 0);
        require(_closingTime >= block.timestamp);

        vault = new RefundVault(_wallet);
        goal = _goal;
        closingTime = _closingTime;
    }

    
    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract's finalization function.
    */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed or goal reached.
    */
    function hasClosed() public view returns (bool) {
        return (block.timestamp > closingTime || goalReached());
    }

    /**
    * @dev Investors can claim refunds here if crowdsale is unsuccessful
    */
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    /**
    * @dev Owner can refund the fund to investor
    */
    function refundToInvestor(address investor) onlyOwner public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(investor);
    }

    /**
    * @dev Checks whether funding goal was reached. 
    * @return Whether funding goal was reached
    */
    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

    /**
    * @dev Close vault and tranfer fund to wallet or enable Refund
    */
    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
    }

    /**
    * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
    */
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

}













/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}







/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}




/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}


/**
 * @title Cycled Token
 */
contract CycledToken is BurnableToken, PausableToken {
    string public constant name = "CycledToken";
    string public constant symbol = "CYD";
    uint8 public constant decimals = 18;
    bool public transferEnabled;

    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 1000000000 * 10**uint256(decimals);

    event TransferEnabled();
    event TransferDisabled();

    
    function CycledToken(
        address _recyclingIncentivesWallet,
        address _cycledTechnologiesWallet,
        address _foundersWallet,
        address _bountyWallet
    ) public {
        require(_recyclingIncentivesWallet != address(0));
        require(_cycledTechnologiesWallet != address(0));
        require(_foundersWallet != address(0));
        require(_bountyWallet != address(0));

        totalSupply_ = HARD_CAP;
        
        //20% of the hard cap, reserve for pre-sale
        balances[msg.sender] = totalSupply_.mul(50).div(100); 
        emit Transfer(0x0, msg.sender, totalSupply_.mul(50).div(100));

        //20% of the hard cap, reserve for recycling incentives 
        balances[_recyclingIncentivesWallet] = totalSupply_.mul(20).div(100); 
        emit Transfer(0x0, _recyclingIncentivesWallet, totalSupply_.mul(20).div(100));

        //15% of the hard cap, reserve for cycled technologies
        balances[_cycledTechnologiesWallet] = totalSupply_.mul(15).div(100); 
        emit Transfer(0x0, _cycledTechnologiesWallet, totalSupply_.mul(15).div(100));

        //10% of the hard cap, reserve for founders
        balances[_foundersWallet] = totalSupply_.mul(10).div(100); 
        emit Transfer(0x0, _foundersWallet, totalSupply_.mul(10).div(100));

        //5% of the hard cap, reserve for bounty
        balances[_bountyWallet] = totalSupply_.mul(5).div(100);  
        emit Transfer(0x0, _bountyWallet, totalSupply_.mul(5).div(100));

        transferEnabled = false;

    }

    function enableTransfers() onlyOwner public {
        transferEnabled = true;
        emit TransferEnabled();
    }

    function disableTransfers() onlyOwner public {
        transferEnabled = false;
        emit TransferDisabled();
    }

    /**
    * @dev transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        require(transferEnabled || msg.sender == owner);
        return super.transfer(to, value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(transferEnabled || from == owner);
        return super.transferFrom(from, to, value);
    }
}




contract Whitelist is Ownable {
    mapping (address => bool) public whitelist;
    address public curator;
    event CurationRightsTransferred(address indexed previousCurator, address indexed newCurator);


    function Whitelist() public {
        curator = owner;
    }

    /**
    * @dev Throws if called by any account other than the curator.
    */
    modifier onlyCurator() {
        require(msg.sender == curator);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newCurator The address to transfer ownership to.
    */
    function transferCurationRights(address newCurator) public onlyOwner {
        require(newCurator != address(0));
        emit CurationRightsTransferred(curator, newCurator);
        curator = newCurator;
    }

    /**
    * @dev Adds address to whitelist.
    * @param investor Address to be added to the whitelist
    */
    function addInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && !whitelist[investor]);
        whitelist[investor] = true;
    }

    /**
    * @dev Adds list of addresses to whitelist.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] _beneficiaries) external onlyCurator {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
    * @dev Remove address to whitelist.
    * @param investor Address to be removed to the whitelist
    */
    function removeInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && whitelist[investor]);
        whitelist[investor] = false;
    }

    /**
    * @dev Check if address is in whitelist or not.
    * @param investor Address to be removed to the whitelist
    */
    function isWhitelisted(address investor) constant external returns (bool result) {
        require(investor != address(0));
        return whitelist[investor];
    }

}


contract CycledCrowdsale is RefundableCrowdsale {
    using SafeMath for uint256;

    // The token being sold
    CycledToken private token;

    // whitelist contract 
    Whitelist private whitelist;

    // Total Token Sold
    uint256 public tokenSold;

    address private tokenWallet;

    //Wallet where store funds 
    address public fundWallet;

    //use to halt the sale
    bool public halted;
    
    // USe to set the base rate
    uint256 private BASE_RATE = 25000;

    //pre sale cap
    uint256 public PRE_SALE_HARD_CAP = 200000000 * 10**uint256(DECIMAL);
    
    //main sale cap
    uint256 public MAIN_SALE_HARD_CAP = 300000000 * 10**uint256(DECIMAL);

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
        require((_now >= date01May2018 && _now <= date31May2018) || (_now >= date13Aug2018 && _now <= date7Sep2018));
        _;
    }

    /**
    * @dev Reverts if halted 
    */
    modifier stopIfHalted {
        require(!halted);
        _;
    }

    function CycledCrowdsale(address _tokenAddress, uint256 _goal, address _whitelistAddress, address _fundWallet) public 
    RefundableCrowdsale(_goal, _fundWallet, date31May2018)
    {
        require(_tokenAddress != address(0));
        require(_whitelistAddress != address(0));
        require(_fundWallet != address(0));
        require(_goal > 0 && _goal <= PRE_SALE_HARD_CAP.add(MAIN_SALE_HARD_CAP));

        tokenWallet = msg.sender;
        fundWallet = _fundWallet;
        token = CycledToken(_tokenAddress);
        whitelist = Whitelist(_whitelistAddress);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }



    /* 
    * @dev (fallback)tranfer tokens to beneficiary as per its investment.
    * @param _beneficiary to which token must transfer
    */
    function buyTokens(address _beneficiary) public stopIfHalted payable {
        uint256 weiAmount = msg.value;
        
        require(_beneficiary != address(0));
        require(weiAmount >= 0.05 ether);
      
        require(whitelist.isWhitelisted(_beneficiary));

        doIssueTokens(_beneficiary, weiAmount);
        forwardFundsToWallet();
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


    function currentSaleCap() internal view onlyWhileOpen returns (uint256 cap) {
        uint64 _now = uint64(block.timestamp);
        if (_now >= date01May2018 && _now <= date31May2018) 
            cap = PRE_SALE_HARD_CAP;// Pre-Sale round
        else if (_now >= date13Aug2018 && _now <= date7Sep2018) 
            cap = MAIN_SALE_HARD_CAP.add(PRE_SALE_HARD_CAP);// Main-Sale round
    }


    /* 
    * @dev issue tokens
    * @param _beneficiary address that the tokens will be sent to.
    * @param _investedWieAmount amount to invest
    */
    function doIssueTokens(address _beneficiary, uint256 _investedWieAmount) internal onlyWhileOpen {
        uint256 _currentSaleCap = currentSaleCap();
        require(tokenSold < _currentSaleCap);

        //Compute number of tokens to transfer
        uint256 tokens = getTokenAfterDiscount(_investedWieAmount, tokenSold);
        
        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);
     

        if (increasedtokenSold > _currentSaleCap){
            tokens = _currentSaleCap.sub(tokenSold);
            increasedtokenSold = tokenSold.add(tokens);
            _investedWieAmount = getTokenPriceAfterDiscount(tokens, tokenSold);
        }
        
        // increase token total supply
        tokenSold = increasedtokenSold;

        //increase wie raised
        weiRaised = weiRaised.add(_investedWieAmount);

        token.transferFrom(tokenWallet, _beneficiary, tokens);

        // event is fired when tokens issued
        emit Issue(issuedIndex++, _beneficiary, tokens);

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
    * @param _tokenAmount Token amount from that the token price to be calculated with including discount
    * @param _totalTokenSold Total token sold so far
    * @return ether amount after applying the discount
    */
    function getTokenPriceAfterDiscount(uint256 _tokenAmount, uint256 _totalTokenSold) public view returns (uint256) {
        
        uint256 round = currentSale();        
        uint256 maxTokenForMaxDiscount = (75000000 * 10**uint256(18));
        
        // No discount
        if (round == 2) {
            return _tokenAmount.div(BASE_RATE);
        } 
        // Pre-Sale discount
        else if (round == 1) {
            if(_totalTokenSold >= maxTokenForMaxDiscount) {
                return _tokenAmount.div(BASE_RATE).div(100).mul(70);
            } else {
                uint256 maxDiscountedTokens = maxTokenForMaxDiscount.sub(_totalTokenSold);
                if (maxDiscountedTokens >= _tokenAmount.div(BASE_RATE).div(100).mul(50)) {
                    return _tokenAmount.div(BASE_RATE).div(100).mul(50);
                } else {
                    uint256 maxDiscounteTokenPrice = maxDiscountedTokens.mul(50).div(BASE_RATE.mul(100));
                    return maxDiscountedTokens.sub((_tokenAmount.add(maxDiscounteTokenPrice)).div(BASE_RATE).div(100).mul(70));
                }
            }
        } 
        return 0;
    }


    /*
    * @dev forward funds
    */
    function forwardFundsToWallet() internal {  
        if (goalReached()) {
            //After goal reached, funds are transfered to fundWallet
            fundWallet.transfer(msg.value);
        } else {
            //Storing funds to vault, till goal reached
            _forwardFunds();
        }   
    }

    /*
    * @dev forward funds to fundwallet if any stuck in contract 
    */
    function forwardFunds() onlyOwner public {
        fundWallet.transfer(address(this).balance);
    }

    // called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner {
        require(halted != true);
        halted = true;
    }

    // called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner {
        require(halted);
        halted = false;
    }
}