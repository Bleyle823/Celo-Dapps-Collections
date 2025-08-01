# 🏦 Escrow Contract UI

<h4 align="center">
  A decentralized escrow system built on Celo blockchain
</h4>

🔒 A secure and transparent escrow smart contract system that enables trustless transactions between buyers and sellers on the Celo network. This project provides a complete frontend interface for managing escrow transactions with built-in dispute resolution.

⚙️ Built using NextJS, RainbowKit, Hardhat, Wagmi, Viem, and TypeScript, deployed on Celo blockchain.

## 🎯 Project Overview

This escrow system allows three parties to participate in secure transactions:

- **Buyer**: Deposits funds and confirms delivery
- **Seller**: Delivers goods/services and can request payment
- **Arbiter**: Resolves disputes between buyer and seller

### Key Features

- ✅ **Secure Escrow**: Funds are held in smart contract until conditions are met
- 🔄 **State Management**: Clear contract states (AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED)
- ⚖️ **Dispute Resolution**: Built-in arbitration system for conflict resolution
- 🎨 **User-Friendly Interface**: Intuitive frontend for all contract interactions
- 🔗 **Celo Integration**: Native support for Celo's mobile-first blockchain
- 📱 **Mobile Responsive**: Works seamlessly on mobile devices

## 🚀 Deployment Details

### Contract Deployment
- **Contract Name**: SimpleEscrow
- **Network**: Celo Mainnet
- **Contract Address**: `0xf76C38A96b4Cf140099BF810556B235E10D62585`
- **Transaction Hash**: `0x16762e2c006c7e74b57ec5d7ef7d7c6d1a1c0208bad58e189f33b92737f5a4da`
- **Gas Used**: 671,480 gas

### Initial Contract State
```
Buyer: 0x231CdF6d31BF1D106DFA88b702B00E4b900628AD
Seller: 0x231CdF6d31BF1D106DFA88b702B00E4b900628AD  
Arbiter: 0x231CdF6d31BF1D106DFA88b702B00E4b900628AD
Amount: 0 wei
State: AWAITING_PAYMENT (0)
Disputed: false
```

> **Note**: For demo purposes, the deployer account is used as buyer, seller, and arbiter. In production, these should be different addresses.

## 🛠 Technical Features

- ✅ **Contract Hot Reload**: Frontend auto-adapts to smart contract changes
- 🪝 **Custom Hooks**: React hooks for seamless contract interactions with TypeScript support
- 🧱 **Web3 Components**: Pre-built components for address display, balance, and contract interactions
- 🔥 **Local Development**: Burner wallet and faucet for testing
- 🔐 **Multi-Wallet Support**: Connect with various wallet providers
- 📊 **Real-time Updates**: Live contract state monitoring
- 🎯 **Role-Based Interface**: Different UI based on user's role (buyer/seller/arbiter)

## 🎮 How It Works

### Contract States
1. **AWAITING_PAYMENT**: Buyer needs to deposit funds
2. **AWAITING_DELIVERY**: Funds deposited, waiting for delivery confirmation
3. **COMPLETE**: Transaction completed successfully
4. **DISPUTED**: Dispute raised, waiting for arbiter resolution

### User Roles & Actions

#### Buyer
- Deposit funds into escrow
- Confirm delivery and release payment
- Raise disputes if needed

#### Seller  
- Request payment release
- Raise disputes if needed

#### Arbiter
- Resolve disputes by awarding funds to buyer or seller

## 🌐 Celo Network Benefits

- **Mobile-First**: Optimized for mobile transactions
- **Low Fees**: Cost-effective transactions
- **Fast**: Quick block times for better UX
- **Eco-Friendly**: Proof of Stake consensus
- **Global**: Accessible worldwide

## 📋 Requirements

Before you begin, you need to install the following tools:

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- Celo wallet (Valora, MetaMask with Celo network, etc.)

## 🚀 Quickstart

To get started with the Escrow Contract UI, follow the steps below:

1. Clone the repository and install dependencies:

```bash
git clone <repository-url>
cd Escrow-Contract-UI
yarn install
```

2. Set up your environment variables:

```bash
# Copy the example environment file
cp packages/hardhat/.env.example packages/hardhat/.env

# Add your private key for deployment
echo "DEPLOYER_PRIVATE_KEY=your_private_key_here" >> packages/hardhat/.env
```

3. Deploy the contract to Celo (or local network for testing):

```bash
# For local testing
yarn chain
yarn deploy

# For Celo mainnet
yarn deploy --network celo
```

4. Start the frontend application:

```bash
yarn start
```

Visit your app on: `http://localhost:3000`

## 🎯 Usage Guide

### For Buyers
1. Connect your wallet to the application
2. Navigate to the home page to see your role and available actions
3. Use the "Debug Contracts" page to deposit funds
4. Confirm delivery when you receive your goods/services

### For Sellers
1. Connect your wallet to the application  
2. Monitor the contract state for payment deposits
3. Request payment release when you've delivered
4. Raise disputes if needed

### For Arbiters
1. Connect your wallet to the application
2. Monitor for disputes in the contract
3. Resolve disputes by awarding funds appropriately

## 🔧 Development

### Project Structure
```
packages/
├── hardhat/          # Smart contracts and deployment
│   ├── contracts/    # Solidity contracts
│   ├── deploy/       # Deployment scripts
│   └── test/         # Contract tests
└── nextjs/           # Frontend application
    ├── app/          # Next.js app router
    ├── components/   # React components
    └── hooks/        # Custom React hooks
```

### Available Scripts
- `yarn chain` - Start local blockchain
- `yarn deploy` - Deploy contracts
- `yarn start` - Start frontend
- `yarn test` - Run tests
- `yarn lint` - Lint code

## 📚 Documentation

- [Celo Documentation](https://docs.celo.org/) - Learn about the Celo blockchain
- [Scaffold-ETH 2 Docs](https://docs.scaffoldeth.io) - Framework documentation
- [Hardhat Documentation](https://hardhat.org/docs) - Smart contract development
- [Next.js Documentation](https://nextjs.org/docs) - Frontend framework

## 🤝 Contributing

We welcome contributions to the Escrow Contract UI!

Please see [CONTRIBUTING.MD](CONTRIBUTING.md) for more information and guidelines for contributing.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Scaffold-ETH 2](https://github.com/scaffold-eth/scaffold-eth-2)
- Deployed on [Celo](https://celo.org/) blockchain
- Powered by [Next.js](https://nextjs.org/) and [Hardhat](https://hardhat.org/)
