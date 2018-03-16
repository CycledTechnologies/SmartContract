var CycledToken = artifacts.require("./CycledToken.sol");
var CycledCrowdsale = artifacts.require("./CycledCrowdsale.sol");
var Whitelist = artifacts.require("./Whitelist.sol");

module.exports = function (deployer) {
  const rate = new web3.BigNumber(25000);
  fundWallet = "0x9af4024c4d6845d440fa6653e29c1e0b8394d040";
  recyclingIncentivesWallet = "0xd1d1c366a1784bf3f84726F8d6B6E682a248429A";
  cycledTechnologiesWallet = "0xeA6727f33f87e24c910217A252126e03A4732982";
  foundersWallet = "0x1033CD9a066b80edE060E0D0Bed736a52Dc7318B";
  bountyWallet = "0xe1902A70ED3E0c5B0C43782dc84e9b1330a1fCc3";

  deployer.deploy(CycledToken, recyclingIncentivesWallet, cycledTechnologiesWallet, foundersWallet, bountyWallet).then(
    async ()=>{
      await deployer.deploy(Whitelist);
      //address _tokenAddress, address _whitelistAddress, address _fundWallet
      await deployer.deploy(CycledCrowdsale, CycledToken.address, Whitelist.address, fundWallet);
    }
  );
};