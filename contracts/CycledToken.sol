pragma solidity 0.4.21;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

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
    * @dev transfer token for a specified address
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