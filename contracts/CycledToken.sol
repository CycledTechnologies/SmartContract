pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/BurnableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract CycledToken is StandardToken, BurnableToken, Ownable {
    string public constant name = "CycledToken";
    string public constant symbol = "CYD";
    uint256 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 55000000;
    uint256 public constant BASE_RATE = 1000;

    bool public tradeable;
    event TradeEnabled();
    event TradeDisabled();

    function CycledToken() public {
        totalSupply = INITIAL_SUPPLY * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        tradeable = false;
    }

    function enableTrading() public onlyOwner {
        tradeable = true;
        TradeEnabled();
    }

    function disableTrading() public onlyOwner {
        tradeable = false;
        TradeDisabled();
    }

    // function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
    //     uint256 tokenBase = ethAmount.mul(BASE_RATE);
    //     uint8[5] memory roundDiscountPercentages = [47, 35, 25, 15, 5];

    //     uint8 roundDiscountPercentage = roundDiscountPercentages[2];
    //     uint8 amountDiscountPercentage = getAmountDiscountPercentage(tokenBase);

    //     tokens = tokenBase.mul(100).div(100 - (roundDiscountPercentage + amountDiscountPercentage));
    // }

    function transfer(address to, uint256 value) public returns (bool) {
        require(tradeable || msg.sender == owner);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(tradeable || msg.sender == owner);
        return super.transferFrom(from, to, value);
    }

}