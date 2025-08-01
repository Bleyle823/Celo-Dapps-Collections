import { expect } from "chai";
import { ethers } from "hardhat";
import { DonationApp } from "../typechain-types";

describe("DonationApp", function () {
  // We define a fixture to reuse the same setup in every test.

  let donationApp: DonationApp;
  let owner: any;
  let user1: any;
  let user2: any;

  before(async () => {
    [owner, user1, user2] = await ethers.getSigners();
    const donationAppFactory = await ethers.getContractFactory("DonationApp");
    donationApp = (await donationAppFactory.deploy()) as DonationApp;
    await donationApp.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct platform owner", async function () {
      expect(await donationApp.platformOwner()).to.equal(owner.address);
    });

    it("Should have the correct platform fee", async function () {
      expect(await donationApp.platformFee()).to.equal(250); // 2.5%
    });

    it("Should start with zero campaigns", async function () {
      expect(await donationApp.totalCampaigns()).to.equal(0);
    });
  });

  describe("Campaign Creation", function () {
    it("Should create a campaign successfully", async function () {
      const title = "Test Campaign";
      const description = "A test campaign for donations";
      const beneficiary = user1.address;
      const goal = ethers.parseEther("1.0");
      const durationInDays = 30;

      await donationApp.createCampaign(title, description, beneficiary, goal, durationInDays);

      const campaign = await donationApp.getCampaign(0);
      expect(campaign.title).to.equal(title);
      expect(campaign.beneficiary).to.equal(beneficiary);
      expect(campaign.goal).to.equal(goal);
      expect(campaign.active).to.be.true;
      expect(await donationApp.totalCampaigns()).to.equal(1);
    });

    it("Should revert with invalid goal", async function () {
      const title = "Invalid Campaign";
      const description = "A campaign with invalid goal";
      const beneficiary = user1.address;
      const goal = 0; // Invalid goal
      const durationInDays = 30;

      await expect(
        donationApp.createCampaign(title, description, beneficiary, goal, durationInDays)
      ).to.be.revertedWithCustomError(donationApp, "InvalidGoal");
    });
  });

  describe("Donations", function () {
    beforeEach(async () => {
      // Create a campaign for testing donations
      const title = "Donation Test Campaign";
      const description = "A campaign for testing donations";
      const beneficiary = user1.address;
      const goal = ethers.parseEther("10.0");
      const durationInDays = 30;

      await donationApp.createCampaign(title, description, beneficiary, goal, durationInDays);
    });

    it("Should accept donations", async function () {
      const donationAmount = ethers.parseEther("0.1");
      const message = "Supporting the cause!";

      await donationApp.connect(user2).donate(0, message, { value: donationAmount });

      const campaign = await donationApp.getCampaign(0);
      expect(campaign.raised).to.be.gt(0);
      expect(campaign.donorCount).to.equal(1);
    });

    it("Should revert donation with zero amount", async function () {
      const message = "Empty donation";

      await expect(
        donationApp.connect(user2).donate(0, message, { value: 0 })
      ).to.be.revertedWith("Donation must be greater than 0");
    });
  });
});
