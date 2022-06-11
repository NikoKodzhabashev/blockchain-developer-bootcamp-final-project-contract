const FundRaiseContract = artifacts.require("FundRaiseContract");
const {
  time,
  expectRevert,
  expectEvent,
} = require("@openzeppelin/test-helpers");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

async function createFreshCampaign(fundRaiseContract, account, weeksToAdd = 1) {
  const latestTimeBlock = await time.latest();
  const additionalWeek = await time.duration.weeks(weeksToAdd);

  const expireOf = parseInt(latestTimeBlock) + parseInt(additionalWeek);
  const goal = 10;
  const title = "Test title";
  const description = "Test description";
  const ipfsHash = "Test ipfsHash";

  await fundRaiseContract.createCampaign(
    expireOf,
    goal,
    title,
    description,
    ipfsHash,
    { from: account }
  );

  return {
    goal,
    expireOf,
    title,
    description,
    ipfsHash,
  };
}
contract("FundRaiseContract", function (accounts) {
  let fundRaiseContract;

  const fundraiser = accounts[0];
  const donator = accounts[1];
  const donation = 1000000;
  const campaignId = 0;

  beforeEach(async () => {
    fundRaiseContract = await deployProxy(FundRaiseContract, [], {
      initializer: "initialize()",
    });
  });

  describe("createCampaign", () => {
    it("should create a new campaign", async () => {
      const { goal, title, expireOf, description, ipfsHash } =
        await createFreshCampaign(fundRaiseContract, fundraiser);

      const campaign = await fundRaiseContract.campaigns(0);

      assert.equal(parseInt(campaign.id.toString()), 0, "Mismatch id");
      assert.equal(parseInt(campaign.goal.toString()), goal, "Mismatch goal");
      assert.equal(
        parseInt(campaign.currentAmount.toString()),
        0,
        "Mismatch currentAmount"
      );
      assert.equal(
        parseInt(campaign.expireOf.toString()),
        parseInt(expireOf.toString()),
        "Mismatch expireOf"
      );
      assert.equal(campaign.description, description, "Mismatch description");
      assert.equal(campaign.title, title, "Mismatch title");
      assert.equal(campaign.ipfsHash, ipfsHash, "Mismatch ipfsHash");
    });
    it("should increment campaign id on campaign creation", async () => {
      await createFreshCampaign(fundRaiseContract, fundraiser);

      const id = await fundRaiseContract.campaignId();
      assert.equal(parseInt(id.toString()), 1, "Mismatch id");
    });
  });

  describe("donate", () => {
    it("should increase the campaign balance on donate when the campaign is active", async () => {
      const { expireOf } = await createFreshCampaign(
        fundRaiseContract,
        fundraiser
      );

      await fundRaiseContract.donate(campaignId, {
        from: donator,
        value: donation,
      });

      const updatedCampaign = await fundRaiseContract.campaigns(campaignId);

      assert.equal(
        parseInt(updatedCampaign.currentAmount.toString()),
        donation,
        "Current amount not equal to the donation"
      );
    });
  });

  describe("withdraw", () => {
    it("should allow the campaign creator to withdraw the money and complete the campaign when it is inactive", async () => {
      const { expireOf } = await createFreshCampaign(
        fundRaiseContract,
        fundraiser
      );
      await time.increase(time.duration.weeks(2));

      const receipt = await fundRaiseContract.withdraw(campaignId, {
        from: fundraiser,
      });

      const updatedCampaign = await fundRaiseContract.campaigns(campaignId);

      assert.equal(
        parseInt(updatedCampaign.status.toString()),
        FundRaiseContract.FundRaiseStatus.Completed
      );
      expectEvent(receipt, "FundRaiseWithdraw");
    });
    it("should not allow non-campaign creator to withdraw the money", async () => {
      const maliciousWithdrawer = accounts[2];
      await createFreshCampaign(fundRaiseContract, fundraiser);

      await expectRevert(
        fundRaiseContract.withdraw(campaignId, { from: maliciousWithdrawer }),
        "Withdrawer not authorized."
      );
    });
    it("should not allow to withdraw the money when the campaign is active", async () => {
      await createFreshCampaign(fundRaiseContract, fundraiser);

      await expectRevert(
        fundRaiseContract.withdraw(campaignId, { from: fundraiser }),
        "Can't withdraw since the campaigns is still active."
      );
    });
  });

  it("it should return all campaigns of an address", async () => {
    const { goal, expireOf, title, description, ipfsHash } =
      await createFreshCampaign(fundRaiseContract, fundraiser);
    const fundraiserCampaigns =
      await fundRaiseContract.getAllCampaignsByAddress();

    expect(fundraiserCampaigns).to.deep.equal([
      [
        "0",
        goal.toString(),
        "0",
        expireOf.toString(),
        description,
        title,
        ipfsHash,
        "0",
      ],
    ]);
  });
});
