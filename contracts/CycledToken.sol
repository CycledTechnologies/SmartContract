pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract CycledToken is StandardToken, Ownable {
    string public constant name = "CycledToken";
    string public constant symbol = "CYD";
    uint8 public constant decimals = 18;


    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 100000000 * 10**uint256(decimals);

    /// Base exchange rate is set to 1 ETH = 10,000 CYD.
    uint256 public constant BASE_RATE = 10000;

    /// token trading opening time
    uint64 private constant date01May2018 = 1525219199;

    // presale start time 15 Mar, 2018
    uint64 private constant date15Mar2018 = 1521072000;

    // presale end time 09 April, 2018
    uint64 private constant date09Apr2018 = 1523232000;
    

    /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// investors can directly invest and get the token when this is set to "true"
    bool public tokenDirectPayable = false;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    //// Modifiers start
    modifier inProgress {
        require(totalSupply < HARD_CAP && !tokenSaleClosed);
        _;
    }

    /// Allow investors to invest directly and recieve tokens
    modifier isDirectPayable {
        require(tokenDirectPayable);
        _;
    }

    /// Allow the closing to happen only once
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    /// Enable token transfer  
    modifier tradingOpen {
        require(uint64(block.timestamp) > date01May2018);
        _;
    }
    //// Modifiers end
    
    function CycledToken() public {
    }

    /// @dev enable the direct pay to contract
    function enableDirectPay() public onlyOwner beforeEnd {
        tokenDirectPayable = true;
    }
  
    /// @dev disable the direct pay to contract
    function disableDirectPay() public onlyOwner beforeEnd {
        tokenDirectPayable = false;
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function ()  public payable isDirectPayable {
        purchaseTokens(msg.sender);
    }

    /// @dev Issue token based on Ether received.
    /// @param _beneficiary Address that newly issued token will be sent to.
    function purchaseTokens(address _beneficiary) public payable inProgress {
        // only accept a minimum amount of ETH?
        require(msg.value >= 0.01 ether);

        uint256 tokens = computeTokenAmount(msg.value);
        doIssueTokens(_beneficiary, tokens);

        /// forward the raised funds to the contract creator
        owner.transfer(this.balance);
    }


    /// @dev Batch issue tokens on the presale
    /// @param _addresses addresses that the presale tokens will be sent to.
    /// @param _addresses the amounts of tokens, with decimals expanded (full).
    function issueTokensMulti(address[] _addresses, uint256[] _tokens) public onlyOwner inProgress {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            doIssueTokens(_addresses[i], _tokens[i].mul(10**uint256(decimals)));
        }
    }

    /// @dev Issue tokens for a single buyer on the presale
    /// @param _beneficiary addresses that the presale tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function issueTokens(address _beneficiary, uint256 _tokens) public onlyOwner inProgress {
        doIssueTokens(_beneficiary, _tokens.mul(10**uint256(decimals)));
    }

    /// @dev issue tokens for a single buyer
    /// @param _beneficiary addresses that the tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));

        // compute without actually increasing it
        uint256 increasedTotalSupply = totalSupply.add(_tokens);
        // roll back if hard cap reached
        require(increasedTotalSupply <= HARD_CAP);

        // increase token total supply
        totalSupply = increasedTotalSupply;
        
        // update the beneficiary balance to number of tokens sent
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);

        // event is fired when tokens issued
        Issue(
            issueIndex++,
            _beneficiary,
            _tokens
        );
    }

    /// @dev Compute the amount of CYD token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase CYD.
    /// @return Amount of CYD token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint64 _now = uint64(block.timestamp);
        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        
        uint8 discount = 0;
        //Giving discount of 30% during 15 Mar, 2018 to 09 Apr, 2018
        if(_now >= date15Mar2018 && _now < date09Apr2018) {
            discount = 30;
        } 

        tokens = tokenBase.mul(discount).div(100).add(tokenBase);
    }

    /// @dev Closes the sale, 
    function close() public onlyOwner beforeEnd {
        /// no more tokens can be issued after this line
        tokenSaleClosed = true;
        
        ///Use to transfer fund in contract to owner 
        owner.transfer(this.balance);
    }

    /// Transfer limited by the tradingOpen modifier (time is 01 May 2018 or later)
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// Transfer limited by the tradingOpen modifier (time is 01 May 2018 or later)
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }
}