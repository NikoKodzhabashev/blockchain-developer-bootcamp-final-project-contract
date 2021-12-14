const FundRaiseContract = artifacts.require("FundRaiseContract");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("FundRaiseContract", function (/* accounts */) {
  it("should assert true", async function () {
    await FundRaiseContract.deployed();
    return assert.isTrue(true);
  });
});
