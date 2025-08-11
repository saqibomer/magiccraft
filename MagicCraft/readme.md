# Blockchain Wallet iOS App

## Overview

This project is an iOS cryptocurrency wallet app built using **MVVM architecture**, leveraging **web3swift 3.3.0** and **WalletCore** libraries to interact with Ethereum and compatible blockchains.

The app supports sending native coins and ERC20 tokens, scanning QR codes for addresses, estimating gas fees, and securely managing wallet keys.

---

## Architecture

### MVVM (Model-View-ViewModel)

- **Model:** Represents data structures such as wallet addresses, tokens, transactions, and key management.
- **ViewModel:** Contains all business logic and blockchain interactions via web3swift and WalletCore. Handles transaction creation, gas estimation, key management, and wallet state.
- **View:** SwiftUI views that bind to ViewModels, providing user interface components such as forms, pickers, transaction lists, and confirmation dialogs.

This pattern improves code separation, testability, and maintainability.

---

## Libraries Used

| Library         | Purpose                                    |
|-----------------|--------------------------------------------|
| [web3swift 3.3.0](https://github.com/skywinder/web3swift) | Ethereum blockchain interaction (transactions, contracts, wallets) |
| [WalletCore](https://github.com/trustwallet/wallet-core) | Secure key management and wallet creation              |
| [SwiftUI](https://developer.apple.com/documentation/swiftui) | Declarative UI framework for iOS                      |
| [Combine](https://developer.apple.com/documentation/combine) | Reactive programming and data binding                   |

---

## Features

- Generate and manage Ethereum-compatible wallets using WalletCore
- Send native coins (ETH, BNB, MATIC) and ERC20 tokens (e.g., MCRT)
- Scan QR codes to input recipient addresses
- Estimate gas fees with detailed confirmation dialogs before sending transactions
- Secure private key storage and retrieval
- Multi-chain support with dynamic RPC URLs and contract addresses

---

## Security
All assets are stored in keychain for safe storage

## How to Build and Run

### Prerequisites

- Xcode 14 or later
- Swift 5.7+
- CocoaPods or Swift Package Manager for dependency management
- Compatible iOS device or Simulator running iOS 15+

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/saqibomer/magiccraft.git
   cd magiccraft
   
   
## To-Do List

- [ ] Access wallet password from keychain
- [ ] Add unit tests
- [ ] Test transactions (Send and Receive)

