pragma solidity 0.4.19;

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