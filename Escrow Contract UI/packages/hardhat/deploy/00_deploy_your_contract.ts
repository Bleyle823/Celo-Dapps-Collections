import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

/**
 * Deploys a contract named "SimpleEscrow" using the deployer account as buyer
 * and constructor arguments for seller and arbiter
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deploySimpleEscrow: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network celo`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` or `yarn account:import` to import your
    existing PK which will fill DEPLOYER_PRIVATE_KEY_ENCRYPTED in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // For demo purposes, we'll use the deployer as both seller and arbiter
  // In a real scenario, you would want to use different addresses
  const seller = deployer;
  const arbiter = deployer;

  await deploy("SimpleEscrow", {
    from: deployer,
    // Contract constructor arguments: seller and arbiter
    args: [seller, arbiter],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  const simpleEscrow = await hre.ethers.getContract<Contract>("SimpleEscrow", deployer);
  console.log("🏦 SimpleEscrow deployed successfully!");
  console.log("📋 Contract details:", await simpleEscrow.getContractDetails());
};

export default deploySimpleEscrow;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags SimpleEscrow
deploySimpleEscrow.tags = ["SimpleEscrow"];
