const FundRaiseContract = artifacts.require("FundRaiseContract");

module.exports = function (_deployer) {
    _deployer.deploy(FundRaiseContract);
};
