// var BaseTrc10Pool = artifacts.require("./BaseTrc10Pool.sol");
// var TNTDivide = artifacts.require("./TNTDivide.sol");
// var KKStake = artifacts.require("./KKStake.sol");
// var BttBank = artifacts.require("./BttBank.sol");
// var TronBankDice = artifacts.require("./TronBankDice.sol");
// var KKPool = artifacts.require("./KKPool.sol");
// var KKReferral = artifacts.require("./KKReferral.sol");
// var KKSeed = artifacts.require("./KKSeed.sol");
// var TronBankDivide = artifacts.require("./TronBankDivide.sol");
// var TronBankStake = artifacts.require("./TronBankStake.sol");
// var TronBankPool = artifacts.require("./TronBankPool.sol");
var UintTest = artifacts.require("./UintTest.sol");

module.exports = function(deployer) {
  // deployer.deploy(TronBankDivide);
  // deployer.deploy(TronBankStake);
  // deployer.deploy(TronBankPool);
  deployer.deploy(UintTest);
  // deployer.deploy(KKDice);
  // deployer.deploy(KKPool);
  // deployer.deploy(KKSeed);
  // deployer.deploy(KKReferral);
};
