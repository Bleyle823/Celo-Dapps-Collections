# 🏛️ Basic DAO

A decentralized autonomous organization (DAO) built with Scaffold-ETH 2, featuring proposal creation, voting mechanisms, and treasury management.

## 📋 Overview

Basic DAO is a complete governance system that allows token holders to:
- Create and vote on proposals
- Execute successful proposals
- Manage a treasury with ETH deposits and withdrawals
- Participate in decentralized decision-making

## 🚀 Features

- **Proposal Management**: Create, vote, and execute proposals
- **Voting System**: Support for For, Against, and Abstain votes with weighted voting power
- **Treasury Management**: Deposit and withdraw ETH through proposals
- **Governance Parameters**: Configurable voting delays, periods, and thresholds
- **Member Management**: Token-based membership system
- **Security**: Reentrancy protection and access controls

## 🏗️ Architecture

### Smart Contracts

1. **SimpleDAO** (`0xB42aF39e206dE9cee21aE0449ceC521ef96306C1`)
   - Main governance contract
   - Handles proposal creation, voting, and execution
   - Manages treasury and member access

2. **GovernanceToken** (`0x4675D74F97Bf20D30311148F23DADacFaD74A620`)
   - ERC-20 token for voting power
   - Determines membership and proposal creation rights

## 🔗 Deployed Contracts

### Local Network (Hardhat)
- **SimpleDAO**: `0xB42aF39e206dE9cee21aE0449ceC521ef96306C1`
- **GovernanceToken**: `0x4675D74F97Bf20D30311148F23DADacFaD74A620`

### Block Explorer Links **Celo Network**
-  https://celoscan.io/address/0xB42aF39e206dE9cee21aE0449ceC521ef96306C1
-  https://celoscan.io/address/0x4675D74F97Bf20D30311148F23DADacFaD74A620 

## ⚙️ Initial Configuration

- **Voting Delay**: 1 day (86400 seconds)
- **Voting Period**: 7 days (604800 seconds)
- **Proposal Threshold**: 1000 tokens
- **Quorum Threshold**: 10% of total token supply
- **Passing Threshold**: 50% of votes cast
- **Treasury Balance**: 0 ETH

## 🛠️ Development

### Prerequisites
- Node.js (>= v20.18.3)
- Yarn
- Git

### Setup

1. **Install dependencies**:
   ```bash
   yarn install
   ```

2. **Start local blockchain**:
   ```bash
   yarn chain
   ```

3. **Deploy contracts**:
   ```bash
   yarn deploy
   ```

4. **Start frontend**:
   ```bash
   yarn start
   ```

5. **Visit the app**: [http://localhost:3000](http://localhost:3000)

### Key Commands

- `yarn chain` - Start local blockchain
- `yarn deploy` - Deploy contracts
- `yarn start` - Start frontend
- `yarn test` - Run tests
- `yarn compile` - Compile contracts

## 📖 Usage

### Joining the DAO
1. Obtain governance tokens
2. Call `joinDAO()` function
3. You're now a member with voting rights

### Creating Proposals
1. Ensure you have enough tokens (≥ 1000)
2. Call `createProposal()` with:
   - Title and description
   - Target contract (or address(0) for treasury operations)
   - ETH value to send
   - Call data

### Voting
1. Wait for voting period to start
2. Call `castVote()` with proposal ID and vote type:
   - 0 = Against
   - 1 = For
   - 2 = Abstain

### Executing Proposals
1. Wait for voting to end
2. Ensure quorum is met and proposal passed
3. Call `executeProposal()` to execute the action

### Treasury Operations
- **Deposit**: Send ETH directly to contract or call `depositToTreasury()`
- **Withdraw**: Create a treasury withdrawal proposal

## 🔧 Governance Parameters

The DAO owner can update these parameters:
- `setVotingDelay()` - Time before voting starts
- `setVotingPeriod()` - Duration of voting
- `setProposalThreshold()` - Minimum tokens to create proposals
- `setQuorumThreshold()` - Minimum participation percentage
- `setPassingThreshold()` - Minimum votes needed to pass

## 🧪 Testing

Run the test suite:
```bash
yarn test
```

## 📁 Project Structure

```
Basic DAO/
├── packages/
│   ├── hardhat/          # Smart contracts and deployment
│   │   ├── contracts/    # Solidity contracts
│   │   ├── deploy/       # Deployment scripts
│   │   └── test/         # Contract tests
│   └── nextjs/           # Frontend application
│       ├── app/          # Next.js app router
│       ├── components/   # React components
│       └── hooks/        # Custom hooks
```

## 🔒 Security Features

- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard
- **Access Control**: Owner-only functions for parameter updates
- **Input Validation**: Comprehensive checks for all inputs
- **State Management**: Proper state transitions for proposals

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

Built with [Scaffold-ETH 2](https://github.com/scaffold-eth/scaffold-eth-2) - An open-source toolkit for building decentralized applications on Ethereum.

---

**Note**: This is a basic implementation for educational purposes. For production use, consider additional security audits and testing.
