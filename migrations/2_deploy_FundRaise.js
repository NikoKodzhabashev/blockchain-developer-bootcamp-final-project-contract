const FundRaiseContract = artifacts.require("FundRaiseContract");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer) {
  await deployProxy(FundRaiseContract, [], {
    initializer: "initialize()",
    deployer,
  });
};
