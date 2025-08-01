# Basic DAO Frontend

This is a comprehensive frontend interface for interacting with the Basic DAO smart contracts built with Next.js and Tailwind CSS.

## Deployed Contracts

The Basic DAO contracts are deployed on the Celo network:

- **SimpleDAO Contract**: [0xB42aF39e206dE9cee21aE0449ceC521ef96306C1](https://celoscan.io/address/0xB42aF39e206dE9cee21aE0449ceC521ef96306C1)
- **GovernanceToken Contract**: [0x4675D74F97Bf20D30311148F23DADacFaD74A620](https://celoscan.io/address/0x4675D74F97Bf20D30311148F23DADacFaD74A620)

## Features

### 🏛️ Proposal Management
- **View Proposals**: See all created proposals with their current status
- **Create Proposals**: Submit new governance proposals with title, description, and optional parameters
- **Vote on Proposals**: Cast votes (For, Against, Abstain) on active proposals
- **Execute Proposals**: Execute successful proposals after voting period ends

### 💰 Treasury Management
- **View Treasury Balance**: See the current ETH balance in the DAO treasury
- **Deposit to Treasury**: Send ETH to the DAO treasury
- **Treasury Withdrawal Proposals**: Create proposals to withdraw funds from treasury

### 🗳️ Governance
- **Token Management**: View and mint governance tokens for testing
- **DAO Settings**: View current governance parameters
- **Voting Power**: See your voting power based on token balance
- **Member Status**: Check if you're a registered DAO member

### 👥 Member Management
- **Join DAO**: Register as a DAO member (requires governance tokens)
- **Member Information**: View member details and voting history

## How to Use

### Getting Started
1. **Connect Wallet**: Connect your wallet using the connect button
2. **Get Tokens**: Go to the Governance tab and mint some governance tokens for testing
3. **Join DAO**: Click "Join DAO" to register as a member
4. **Start Governing**: Create proposals and participate in voting

### Creating a Proposal
1. Navigate to the Proposals tab
2. Click "Create Proposal"
3. Fill in the proposal details:
   - **Title**: Short, descriptive title
   - **Description**: Detailed explanation of the proposal
   - **Target Contract** (optional): Address of contract to call
   - **ETH Value** (optional): Amount of ETH to send with the proposal
4. Click "Create Proposal"

### Voting on Proposals
1. Find an active proposal in the Proposals tab
2. Click one of the voting buttons:
   - **Vote For** (green): Support the proposal
   - **Vote Against** (red): Oppose the proposal
   - **Abstain** (yellow): Neutral vote
3. Confirm the transaction

### Managing Treasury
1. **Deposit**: Go to Treasury tab and enter amount to deposit
2. **Withdraw**: Create a treasury withdrawal proposal through the Proposals tab

## Smart Contract Integration

The frontend integrates with two main contracts:

### SimpleDAO Contract
- `createProposal()`: Create new governance proposals
- `castVote()`: Vote on active proposals
- `executeProposal()`: Execute successful proposals
- `joinDAO()`: Register as a DAO member
- `depositToTreasury()`: Send ETH to treasury

### GovernanceToken Contract
- `balanceOf()`: Check token balance
- `mint()`: Create new tokens (owner only)
- `transfer()`: Transfer tokens to other addresses

## Technical Details

### Frontend Architecture
- **Framework**: Next.js 14 with App Router
- **Styling**: Tailwind CSS with DaisyUI
- **State Management**: React hooks with wagmi
- **Contract Interaction**: Custom hooks for contract interaction

### Key Components
- `ProposalCard`: Individual proposal display with voting
- `TokenManager`: Token minting and balance management
- `Address`: Ethereum address display component
- Modal dialogs for proposal creation

### Contract Hooks Used
- `useScaffoldReadContract`: Read contract state
- `useScaffoldWriteContract`: Write contract functions
- `useAccount`: Get connected wallet address

## Development

### Running Locally
```bash
# Start local blockchain
yarn chain

# Deploy contracts
yarn deploy

# Start frontend
yarn start
```

### Testing the DAO
1. Deploy contracts to local network
2. Mint governance tokens to test accounts
3. Join the DAO with test accounts
4. Create and vote on proposals
5. Test treasury operations

## Branding

This application has been customized with Basic DAO branding throughout:
- **App Name**: Basic DAO
- **Logo**: Custom DAO logo
- **Theme**: Consistent branding across all components
- **Documentation**: Updated to reflect Basic DAO functionality

## Security Considerations

- Only the token owner can mint new tokens
- Users must hold tokens to join the DAO
- Proposal creation requires minimum token threshold
- Voting is weighted by token balance
- Treasury withdrawals require proposal approval

## Future Enhancements

- Real-time proposal updates
- Advanced filtering and search
- Proposal templates
- Member directory
- Governance analytics
- Mobile optimization 