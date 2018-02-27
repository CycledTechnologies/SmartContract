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
    
    function CycledToken(
        address _preSaleWallet,
        address _mainSaleWallet,
        address _recyclingIncentivesWallet,
        address _cycledTechnologiesWallet,
        address _foundersWallet,
        address _bountyWallet
    ) public {
        totalSupply = HARD_CAP;
        //20% of the hard cap, reserve for pre-sale
        balances[_preSaleWallet] = totalSupply.mul(20).div(100); 
        Transfer(0x0, _preSaleWallet, totalSupply);

        //30% of the hard cap, reserve for pre-sale
        balances[_mainSaleWallet] = totalSupply.mul(30).div(100); 
        Transfer(0x0, _mainSaleWallet, totalSupply);

        //20% of the hard cap, reserve for recycling incentives 
        balances[_recyclingIncentivesWallet] = totalSupply.mul(20).div(100); 
        Transfer(0x0, _recyclingIncentivesWallet, totalSupply);

        //15% of the hard cap, reserve for cycled technologies
        balances[_cycledTechnologiesWallet] = totalSupply.mul(15).div(100); 
        Transfer(0x0, _cycledTechnologiesWallet, totalSupply);

        //10% of the hard cap, reserve for founders
        balances[_foundersWallet] = totalSupply.mul(10).div(100); 
        Transfer(0x0, _foundersWallet, totalSupply);

        //5% of the hard cap, reserve for bounty
        balances[_bountyWallet] = totalSupply.mul(5).div(100);  
        Transfer(0x0, _bountyWallet, totalSupply);

    }

}