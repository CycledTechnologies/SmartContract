var CycledToken = artifacts.require("./CycledToken.sol");
var CycledCrowdsale = artifacts.require("./CycledCrowdsale.sol");
var Whitelist = artifacts.require("./Whitelist.sol");

module.exports = function (deployer) {
  const rate = new web3.BigNumber(25000);
  const saleTokens = new web3.BigNumber(web3.toWei("500000000", "ether"));

  fundWallet = "0xad2718380f4f95a4636088606eddd66dd56b517f";
  recyclingIncentivesWallet = "0x41407962c3a18edbcaa98a5cc071433111b66ccc";
  cycledTechnologiesWallet = "0xfb51ebe7b377f11d5d38112979ed7ffd27cc26fc";
  foundersWallet = "0xa9207175a2a8425db5c496e120b2ec28ba0a39e4";
  bountyWallet = "0x33ec7ecf1a5aaebdf97a8603dcf3f04127d21035";

  deployer.deploy(CycledToken, recyclingIncentivesWallet, cycledTechnologiesWallet, foundersWallet, bountyWallet).then(
    async ()=>{
      await deployer.deploy(Whitelist);
      //address _tokenAddress, address _whitelistAddress, address _fundWallet
      await deployer.deploy(CycledCrowdsale, CycledToken.address, Whitelist.address, fundWallet);
    }
  );
  /* 
  * Allowing CycledCrowdsale to distribute tokens. 
  **/
  deployer.then(function() {
    CycledToken.deployed().then(function(instance) {
      instance.approve(CycledCrowdsale.address, saleTokens);
    });
  });

};