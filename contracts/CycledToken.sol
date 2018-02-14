pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract CycledToken is StandardToken, Ownable {
    string public constant name = "CycledToken";
    string public constant symbol = "CYD";
    uint8 public constant decimals = 18;


    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 100000000 * 10**uint256(decimals);

    /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// investors can directly invest and get the token when this is set to "true"
    bool public tradingOpen = false;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    //// Modifiers start
    modifier inProgress {
        require(totalSupply < HARD_CAP && !tokenSaleClosed);
        _;
    }

    /// Allow the closing to happen only once
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    //// Modifiers end
    
    function CycledToken() public {
    }

     /// @dev enable the token trading
    function enableTrading() public onlyOwner {
        tradingOpen = true;
    }
  
    /// @dev disable the token trading
    function disableTrading() public onlyOwner {
        tradingOpen = false;
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
        
        // event for token transfer
        Transfer(msg.sender, _beneficiary, _tokens);
        // event is fired when tokens issued
        Issue(issueIndex++, _beneficiary, _tokens);
    }

    /// @dev Closes the sale, 
    function close() public onlyOwner beforeEnd {
        /// no more tokens can be issued after this line
        tokenSaleClosed = true;
        
    }

    /// Transfer limited by the tradingOpen modifier 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(tradingOpen);
        return super.transferFrom(_from, _to, _value);
    }

    /// Transfer limited by the tradingOpen modifier 
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(tradingOpen);
        return super.transfer(_to, _value);
    }
}