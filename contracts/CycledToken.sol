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


    address public recyclingIncentivesWallet = 0xd1d1c366a1784bf3f84726F8d6B6E682a248429A;
    address public cycledTechnologiesWallet = 0xeA6727f33f87e24c910217A252126e03A4732982;
    address public foundersWallet = 0x1033CD9a066b80edE060E0D0Bed736a52Dc7318B;
    address public bountyWallet = 0xe1902A70ED3E0c5B0C43782dc84e9b1330a1fCc3;

    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 1000000000 * 10**uint256(decimals);
    
    function CycledToken() public {
        totalSupply = HARD_CAP;

        //50% of the hard cap, reserve for sale
        balances[msg.sender] = totalSupply.mul(50).div(100); 
        Transfer(0x0, msg.sender, totalSupply);

        //20% of the hard cap, reserve for recycling incentives 
        balances[recyclingIncentivesWallet] = totalSupply.mul(20).div(100); 
        Transfer(0x0, recyclingIncentivesWallet, totalSupply);

        //15% of the hard cap, reserve for cycled technologies
        balances[cycledTechnologiesWallet] = totalSupply.mul(15).div(100); 
        Transfer(0x0, cycledTechnologiesWallet, totalSupply);

        //10% of the hard cap, reserve for founders
        balances[foundersWallet] = totalSupply.mul(10).div(100); 
        Transfer(0x0, foundersWallet, totalSupply);

        //5% of the hard cap, reserve for bounty
        balances[bountyWallet] = totalSupply.mul(5).div(100);  
        Transfer(0x0, bountyWallet, totalSupply);

    }

}