var CycledToken = artifacts.require("./CycledToken.sol");
var TokenDistributor = artifacts.require("./TokenDistributor.sol");

module.exports = function (deployer) {
  const rate = new web3.BigNumber(25000);
  preSaleWallet = "0xf7298C73F456aFBfFB3eeE76BfB6E1b598A6644E";
  mainSaleWallet = "0xa40Fc158d4aaC56AfB40775a8a603b3DB45c8F22";
  recyclingIncentivesWallet = "0xd1d1c366a1784bf3f84726F8d6B6E682a248429A";
  cycledTechnologiesWallet = "0xeA6727f33f87e24c910217A252126e03A4732982";
  foundersWallet = "0x1033CD9a066b80edE060E0D0Bed736a52Dc7318B";
  bountyWallet = "0xe1902A70ED3E0c5B0C43782dc84e9b1330a1fCc3";

  deployer.deploy(CycledToken, preSaleWallet, mainSaleWallet, recyclingIncentivesWallet, cycledTechnologiesWallet, foundersWallet, bountyWallet).then(
    async ()=>{
      //uint256 _rate, address _tokenAddress, address _preSaleWallet,address _mainSaleWallet
      await deployer.deploy(TokenDistributor, rate, CycledToken.address, preSaleWallet, mainSaleWallet);
    }
  );
  // deployer.then(function() {
  //   CTestToken.deployed().then(function(instance) {
  //     instance.approve(TokenDistributor.address, cap);
  //   });
  // });

};