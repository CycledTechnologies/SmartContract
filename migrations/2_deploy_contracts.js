var CycledToken = artifacts.require("./CycledToken.sol");

module.exports = function(deployer) {
  deployer.deploy(CycledToken);
};

// var TestToken = artifacts.require("./TestToken.sol");

// module.exports = function(deployer) {
//   deployer.deploy(TestToken);
// };
