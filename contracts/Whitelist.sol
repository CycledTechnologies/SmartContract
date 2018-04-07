pragma solidity 0.4.21;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Whitelist is Ownable {
    mapping (address => bool) public whitelist;


    function Whitelist() public {
    }

    /**
    * @dev Adds address to whitelist.
    * @param investor Address to be added to the whitelist
    */
    function addInvestor(address investor) external onlyOwner {
        require(investor != 0x0 && !whitelist[investor]);
        whitelist[investor] = true;
    }

    /**
    * @dev Adds list of addresses to whitelist.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
    * @dev Remove address to whitelist.
    * @param investor Address to be removed to the whitelist
    */
    function removeInvestor(address investor) external onlyOwner {
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