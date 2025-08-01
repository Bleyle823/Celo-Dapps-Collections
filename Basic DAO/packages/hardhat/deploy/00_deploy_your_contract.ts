import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

/**
 * Deploys a SimpleDAO contract with a governance token
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deploySimpleDAO: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
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

  // First, deploy a simple ERC20 governance token for testing
  const governanceTokenDeployment = await deploy("GovernanceToken", {
    contract: "contracts/mocks/MockERC20.sol:MockERC20", // We'll need to create this mock contract
    from: deployer,
    args: ["DAO Governance Token", "DGOV", hre.ethers.parseEther("1000000")], // 1M tokens
    log: true,
    autoMine: true,
  });

  // Deploy the SimpleDAO contract
  await deploy("SimpleDAO", {
    from: deployer,
    // Contract constructor arguments - governance token address
    args: [governanceTokenDeployment.address],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contracts to interact with them after deploying
  const simpleDAO = await hre.ethers.getContract<Contract>("SimpleDAO", deployer);
  const governanceToken = await hre.ethers.getContract<Contract>("GovernanceToken", deployer);
  
  console.log("🏛️  SimpleDAO deployed at:", await simpleDAO.getAddress());
  console.log("🪙  Governance Token deployed at:", await governanceToken.getAddress());
  console.log("📊 Initial DAO settings:");
  
  const settings = await simpleDAO.getDAOSettings();
  console.log("   - Voting Delay:", settings[0].toString(), "seconds");
  console.log("   - Voting Period:", settings[1].toString(), "seconds");
  console.log("   - Proposal Threshold:", hre.ethers.formatEther(settings[2]), "tokens");
  console.log("   - Quorum Threshold:", settings[3].toString(), "%");
  console.log("   - Passing Threshold:", settings[4].toString(), "%");
  console.log("   - Treasury Balance:", hre.ethers.formatEther(settings[5]), "ETH");
};

export default deploySimpleDAO;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags SimpleDAO
deploySimpleDAO.tags = ["SimpleDAO"];
