var CTestToken = artifacts.require("./CTestToken.sol");
var TokenDistributor = artifacts.require("./TokenDistributor.sol");

module.exports = function (deployer) {
  const rate = new web3.BigNumber(25000);
  const cap = new web3.BigNumber(web3.toWei("200000000", "ether")); //Number of tokens
  //   uint256 _rate, address _tokenIssueWallet, address _tokenAddress
  deployer.deploy(CTestToken).then(
    async ()=>{
      console.log("token_address-", CTestToken.address);
      await deployer.deploy(TokenDistributor, rate, CTestToken.address);
    }
  );
  // deployer.then(function() {
  //   CTestToken.deployed().then(function(instance) {
  //     instance.approve(TokenDistributor.address, cap);
  //   });
  // });

};