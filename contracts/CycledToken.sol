pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/PausableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/BurnableToken.sol";

/**
 * @title Cycled Token
 */
contract CycledToken is PausableToken, BurnableToken {
    string public constant name = "CycledToken";
    string public constant symbol = "CYD";
    uint8 public constant decimals = 18;

    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 1000000000 * 10**uint256(decimals);
    
    function CycledToken() public {
        totalSupply = HARD_CAP;
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
    }

}