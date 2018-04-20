pragma solidity 0.4.21;


import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./RefundVault.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";


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

    //Closing time of first sale
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
    function finalizePresale() internal {
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
    function _forwardFunds(uint256 investedWieAmount) internal {
        vault.deposit.value(investedWieAmount)(msg.sender);
    }

}
