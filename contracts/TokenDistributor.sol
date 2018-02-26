pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CycledToken.sol";

contract TokenDistributor is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CycledToken private token;

    // USe to set the base rate
    uint256 private baseRate;

    // Total Token Sold
    uint256 public tokenSold;

    // Total Wei raised
    uint256 public weiRaised = 0;

    uint8 private constant DECIMAL = 18;

    /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    /// Maximum tokens to be allocated on the PreSale (20% of the hard cap)
    uint256 public constant PRESALE_SUPPLY = 200000000 * 10**uint256(DECIMAL);

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    modifier inProgress {
        require(tokenSold <= PRESALE_SUPPLY && !tokenSaleClosed);
        _;
    }

    /// Allow the closing to happen only once
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _tokenAddress of the token being sold
    */
    function TokenDistributor(uint256 _rate, address _tokenAddress) public {
        require(_rate > 0);
        require(_tokenAddress != address(0));

        baseRate = _rate;
        token = CycledToken(_tokenAddress);
    }

    /// @dev Issue tokens for a single buyer on the presale
    /// @param _beneficiary addresses that the presale tokens will be sent to.
    /// @param _investedWieAmount the amount to invest, with decimals expanded (full).
    function issueTokens(address _beneficiary, uint256 _investedWieAmount) public onlyOwner inProgress {
        require(_beneficiary != address(0));
        require(_investedWieAmount != 0);

        //Compute number of tokens to transfer
        uint256 tokens = getTokenAmount(_investedWieAmount);

        // compute without actually increasing it
        uint256 increasedtokenSold = tokenSold.add(tokens);

        // roll back if hard cap reached
        require(increasedtokenSold <= PRESALE_SUPPLY);

        // increase token total supply
        tokenSold = increasedtokenSold;
        //increase wie raised
        weiRaised = weiRaised.add(_investedWieAmount);

        //Transfering tokens from issue token wallet to beneficiary wallet
        token.transferFrom(owner, _beneficiary, tokens);

        // event is fired when tokens issued
        Issue(issueIndex++, _beneficiary, tokens);
    }
    

    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens) {
        uint256 _tokenSold = tokenSold * 10**uint256(DECIMAL);
        uint256 _tokenBase = _weiAmount.mul(baseRate);
        uint256 _amountFor30perDiscount = 75000000 * 10**uint256(DECIMAL);

        if (_tokenSold >= _amountFor30perDiscount)
            tokens = _tokenBase.mul(30).div(100).add(_tokenBase);
        else
            tokens = _tokenBase.mul(50).div(100).add(_tokenBase);
    }

    function close() public onlyOwner beforeEnd {
        tokenSaleClosed = true;
    }

}