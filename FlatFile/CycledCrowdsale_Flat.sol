pragma solidity 0.4.19;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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
 *
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


/**
 * @title Cycled Token
 */
contract CycledToken is PausableToken, BurnableToken {
    string public constant name = "CycledToken";
    string public constant symbol = "CYD";
    uint8 public constant decimals = 18;

    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 1000000000 * 10**uint256(decimals);
    
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

        totalSupply = HARD_CAP;
        
        //20% of the hard cap, reserve for pre-sale
        balances[msg.sender] = totalSupply.mul(50).div(100); 
        Transfer(0x0, msg.sender, totalSupply.mul(50).div(100));

        //20% of the hard cap, reserve for recycling incentives 
        balances[_recyclingIncentivesWallet] = totalSupply.mul(20).div(100); 
        Transfer(0x0, _recyclingIncentivesWallet, totalSupply.mul(20).div(100));

        //15% of the hard cap, reserve for cycled technologies
        balances[_cycledTechnologiesWallet] = totalSupply.mul(15).div(100); 
        Transfer(0x0, _cycledTechnologiesWallet, totalSupply.mul(15).div(100));

        //10% of the hard cap, reserve for founders
        balances[_foundersWallet] = totalSupply.mul(10).div(100); 
        Transfer(0x0, _foundersWallet, totalSupply.mul(10).div(100));

        //5% of the hard cap, reserve for bounty
        balances[_bountyWallet] = totalSupply.mul(5).div(100);  
        Transfer(0x0, _bountyWallet, totalSupply.mul(5).div(100));

    }

}




contract Whitelist is Ownable {
    mapping (address => bool) public whitelist;


    function Whitelist() public {
    }


    function addInvestor(address investor) external onlyOwner {
        require(investor != 0x0 && !whitelist[investor]);
        whitelist[investor] = true;
    }


    function removeInvestor(address investor) external onlyOwner {
        require(investor != 0x0 && whitelist[investor]);
        whitelist[investor] = false;
    }


    function isWhitelisted(address investor) constant external returns (bool result) {
        require(investor != address(0));
        return whitelist[investor];
    }

}


contract CycledCrowdsale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CycledToken private token;

    // whitelist contract 
    Whitelist private whitelist;

    // Total Token Sold
    uint256 public tokenSold;

    address private tokenWallet;

    //Wallet where store funds 
    address private fundWallet;

    //use to halt the sale
    bool public halted;
    
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

    /**
    * @dev Reverts if halted 
    */
    modifier stopIfHalted {
      require(!halted);
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



    /* 
    * @dev (fallback)tranfer tokens to beneficiary as per its investment.
    * @param _beneficiary to which token must transfer
    */
    function buyTokens(address _beneficiary) public stopIfHalted payable {
        uint256 weiAmount = msg.value;
        require(whitelist.isWhitelisted(_beneficiary));
        doIssueTokens(_beneficiary, weiAmount);
        fundWallet.transfer(weiAmount);
    }

        
    /* 
    * @dev tranfer tokens to beneficiary as per its investment.
    * @param _beneficiary to which tranfer token
    * @param _investedWieAmount investment amount by the beneficiary
    */
    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public onlyOwner stopIfHalted onlyWhileOpen {
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

        require(_beneficiary != address(0));
        require(_investedWieAmount >= 0.05 ether);
        
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
    * @dev forward funds to fundwallet if any stuck in contract 
    */
    function forwardFunds() onlyOwner public {
        address thisAddress = this;
        fundWallet.transfer(thisAddress.balance);
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