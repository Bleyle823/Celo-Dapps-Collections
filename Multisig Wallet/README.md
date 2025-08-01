# 🔐 Celo Multisig Wallet

<h4 align="center">
  <a href="https://docs.scaffoldeth.io">Scaffold-ETH 2 Documentation</a> |
  <a href="https://scaffoldeth.io">Scaffold-ETH 2 Website</a>
</h4>

🧪 A decentralized multisignature wallet built on the **Celo blockchain** using Scaffold-ETH 2. This project enables secure, multi-party control over digital assets and transactions, requiring multiple approvals before execution.

## 🎯 Project Overview

This multisig wallet allows multiple owners to:
- **Submit transactions** for approval
- **Confirm or revoke** transaction approvals
- **Execute transactions** once sufficient confirmations are reached
- **Manage shared funds** securely with multi-party consensus

## 🚀 Deployed Contract

**Contract Address**: [`0x8e696F31f089892a1c407F398922Ad71888f5f85`](https://explorer.celo.org/mainnet/address/0x8e696F31f089892a1c407F398922Ad71888f5f85)

**Network**: Celo Mainnet

**Deployment Transaction**: [`0x5ac8b25944051425166e17ae67d6028158c601aa819cf7a275abe95f18c82288`](https://explorer.celo.org/mainnet/tx/0x5ac8b25944051425166e17ae67d6028158c601aa819cf7a275abe95f18c82288)

**Initial Configuration**:
- **Owners**: `0x231CdF6d31BF1D106DFA88b702B00E4b900628AD`
- **Required Confirmations**: 1

## ⚙️ Built with

- **Smart Contracts**: Solidity, Hardhat
- **Frontend**: NextJS, RainbowKit, Wagmi, Viem, TypeScript
- **Blockchain**: Celo Network
- **Development Framework**: Scaffold-ETH 2

## 🔧 Key Features

- ✅ **Multi-Party Control**: Multiple owners can manage shared funds
- 🛡️ **Secure Transactions**: Require multiple confirmations before execution
- 🔄 **Transaction Management**: Submit, confirm, revoke, and execute transactions
- 💰 **Fund Management**: Accept and manage CELO and other tokens
- 🪝 **Custom Hooks**: React hooks for seamless contract interaction
- 🧱 **Web3 Components**: Pre-built components for rapid UI development
- 🔥 **Burner Wallet & Local Faucet**: Test with burner wallet and local faucet
- 🔐 **Wallet Integration**: Connect to various wallet providers

## 🏗️ Smart Contract Features

The `SimpleMultisig` contract provides:

- **Owner Management**: Add/remove owners with consensus
- **Transaction Submission**: Propose transactions for approval
- **Confirmation System**: Multi-signature approval workflow
- **Transaction Execution**: Execute approved transactions
- **Fund Deposits**: Accept CELO and token deposits
- **Balance Tracking**: Monitor wallet balances
- **Event Logging**: Comprehensive transaction history

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with the Celo Multisig Wallet, follow the steps below:

1. Clone and install dependencies:

```bash
git clone <repository-url>
cd Multisig-Wallet
yarn install
```

2. Run a local network in the first terminal:

```bash
yarn chain
```

This command starts a local Celo network for testing and development.

3. On a second terminal, deploy the multisig contract:

```bash
yarn deploy
```

This command deploys the SimpleMultisig contract to the local network.

4. On a third terminal, start your NextJS app:

```bash
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your multisig wallet using the `Debug Contracts` page.

## 🌐 Celo Network Integration

This project is specifically designed for the Celo blockchain, which offers:

- **Fast Transactions**: Quick confirmation times
- **Low Fees**: Cost-effective transaction costs
- **Mobile-First**: Optimized for mobile DeFi applications
- **Carbon Negative**: Environmentally conscious blockchain
- **Stablecoins**: Native support for cUSD and cEUR

## 📚 Documentation

- **Scaffold-ETH 2 Docs**: [docs.scaffoldeth.io](https://docs.scaffoldeth.io)
- **Celo Documentation**: [docs.celo.org](https://docs.celo.org)
- **Celo Explorer**: [explorer.celo.org](https://explorer.celo.org)

## 🤝 Contributing

We welcome contributions to the Celo Multisig Wallet!

Please see [CONTRIBUTING.MD](CONTRIBUTING.md) for more information and guidelines for contributing to this project.

## 📄 License

This project is licensed under the MIT License - see the [LICENCE](LICENCE) file for details.
