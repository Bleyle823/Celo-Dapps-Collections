import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

/**
 * Deploys a contract named "SimpleMultisig" using the deployer account and
 * constructor arguments set to include the deployer as an owner with 1 confirmation required
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deploySimpleMultisig: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network sepolia`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` or `yarn account:import` to import your
    existing PK which will fill DEPLOYER_PRIVATE_KEY_ENCRYPTED in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Define the owners array - starting with just the deployer
  const owners = [deployer];
  const numConfirmationsRequired = 1; // Require 1 confirmation for single owner

  await deploy("SimpleMultisig", {
    from: deployer,
    // Contract constructor arguments
    args: [owners, numConfirmationsRequired],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  const simpleMultisig = await hre.ethers.getContract<Contract>("SimpleMultisig", deployer);
  console.log("🏦 SimpleMultisig deployed at:", await simpleMultisig.getAddress());
  console.log("👥 Owners:", await simpleMultisig.getOwners());
  console.log("✅ Required confirmations:", await simpleMultisig.numConfirmationsRequired());
};

export default deploySimpleMultisig;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags SimpleMultisig
deploySimpleMultisig.tags = ["SimpleMultisig"];
