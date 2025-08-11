//
//  SendViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//
import Foundation
import Combine
import WalletCore
import web3swift
import Web3Core
import BigInt


@MainActor
class SendViewModel: ObservableObject {
    @Published var recipientAddress: String = ""
    @Published var amountString: String = ""
    @Published var selectedChainName: String = ""
    @Published var tokenType: TokenType = .native
    
    @Published var gasEstimate: BigUInt?
    @Published var gasPrice: BigUInt?
    @Published var estimatedFeeEth: String = ""
    @Published var isEstimatingGas = false
    @Published var isSending = false
    @Published var txHash: String?
    @Published var errorMessage: String?
    @Published var showConfirmation = false
    @Published var keystore: EthereumKeystoreV3? = nil
    
    private let walletAddress: EthereumAddress
    private var web3: Web3Network!
    private let password: String
    
    let chains: [Chain] = [
        Chain(name: "Ethereum",
              rpcUrl: "https://mainnet.infura.io/v3/526da39fa0f8458aad9da12c9f5eb7d3",
              nativeSymbol: "ETH",
              mcrtContractAddress: "0xde16ce60804a881e9f8c4ebb3824646edecd478d",
              explorerTxUrlPrefix: "https://etherscan.io/tx/"),
        Chain(name: "Binance Smart Chain",
              rpcUrl: "https://bsc-dataseed.binance.org/",
              nativeSymbol: "BNB",
              mcrtContractAddress: "0x4b8285aB433D8f69CB48d5Ad62b415ed1a221e4f",
              explorerTxUrlPrefix: "https://bscscan.com/tx/"),
        Chain(name: "Polygon",
              rpcUrl: "https://polygon-rpc.com/",
              nativeSymbol: "MATIC",
              mcrtContractAddress: "", // add if known
              explorerTxUrlPrefix: "https://polygonscan.com/tx/")
    ]
    
    // You must provide wallet address, keystore, and web3 network at init
    init(walletAddress: EthereumAddress, password: String) {
        self.walletAddress = walletAddress
        self.password = password
        
    }
    func loadKeystore() async {
        guard let privateKey = privateKeyData(fromPasscode: password) else {
            errorMessage = "Failed to retrieve private key from Keychain"
            return
        }
        do {
            self.keystore = try createKeystore(fromPrivateKey: privateKey, password: password)
        } catch {
            errorMessage = "Failed to create keystore: \(error.localizedDescription)"
        }
    }
    
    func estimateGas() async {
        guard let toAddress = EthereumAddress(recipientAddress),
              let amount = Utilities.parseToBigUInt(amountString, decimals: 18) // assuming 18 decimals; adjust if needed
        else {
            errorMessage = "Invalid recipient or amount"
            return
        }
        
        isEstimatingGas = true
        errorMessage = nil
        
        do {
            var transaction: CodableTransaction = .emptyTransaction
            transaction.from = walletAddress
            
            var writeOperation: WriteOperation
            
            switch tokenType {
            case .native:
                transaction.to = toAddress
                transaction.value = amount
                
                let contract = web3.web3.contract(Web3.Utils.coldWalletABI, at: toAddress, abiVersion: 2)
                contract?.transaction = transaction
                guard let op = contract?.createWriteOperation("fallback", parameters: []) else {
                    throw NSError(domain: "SendViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fallback operation not created"])
                }
                writeOperation = op
                
            case .erc20(let contractAddress):
                transaction.to = contractAddress
                transaction.value = 0
                
                let contract = web3.web3.contract(Web3.Utils.erc20ABI, at: contractAddress, abiVersion: 2)
                contract?.transaction = transaction
                guard let op = contract?.createWriteOperation("transfer", parameters: [toAddress as AnyObject, amount as AnyObject]) else {
                    throw NSError(domain: "SendViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Transfer operation not created"])
                }
                writeOperation = op
            }
            
            let estimatedGas = try await web3.web3.eth.estimateGas(for: writeOperation.transaction)
            let gasPrice = try await web3.web3.eth.gasPrice()
            
            self.gasEstimate = estimatedGas
            self.gasPrice = gasPrice
            
            let fee = gasPrice * estimatedGas
            self.estimatedFeeEth = weiToEthString(fee)
            
            showConfirmation = true
        } catch {
            errorMessage = "Gas estimation failed: \(error.localizedDescription)"
        }
        isEstimatingGas = false
    }
    
    func sendTransaction() async {
        guard let toAddress = EthereumAddress(recipientAddress),
              let amount = Utilities.parseToBigUInt(amountString, decimals: 18) // adjust decimals as needed
        else {
            errorMessage = "Invalid recipient or amount"
            return
        }
        
        isSending = true
        errorMessage = nil
        txHash = nil
        
        do {
            var transaction: CodableTransaction = .emptyTransaction
            transaction.from = walletAddress
            
            var writeOperation: WriteOperation
            
            switch tokenType {
            case .native:
                transaction.to = toAddress
                transaction.value = amount
                
                let contract = web3.web3.contract(Web3.Utils.coldWalletABI, at: toAddress, abiVersion: 2)
                contract?.transaction = transaction
                guard let op = contract?.createWriteOperation("fallback", parameters: []) else {
                    throw NSError(domain: "SendViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Fallback operation not created"])
                }
                writeOperation = op
                
            case .erc20(let contractAddress):
                transaction.to = contractAddress
                transaction.value = 0
                
                let contract = web3.web3.contract(Web3.Utils.erc20ABI, at: contractAddress, abiVersion: 2)
                contract?.transaction = transaction
                guard let op = contract?.createWriteOperation("transfer", parameters: [toAddress as AnyObject, amount as AnyObject]) else {
                    throw NSError(domain: "SendViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Transfer operation not created"])
                }
                writeOperation = op
            }
            
            transaction.gasLimit = try await web3.web3.eth.estimateGas(for: writeOperation.transaction)
            transaction.gasPrice = try await web3.web3.eth.gasPrice()
            
            let policies = Policies(
                noncePolicy: .latest,
                gasLimitPolicy: .manual(transaction.gasLimit),
                gasPricePolicy: .manual(transaction.gasPrice ?? 0),
                maxFeePerGasPolicy: .automatic,
                maxPriorityFeePerGasPolicy: .automatic
            )
            
            let hash = try await writeOperation.writeToChain(password: password, policies: policies).hash
            txHash = hash
        } catch {
            errorMessage = "Transaction failed: \(error.localizedDescription)"
        }
        isSending = false
    }
    
    func updateRecipient(with scannedCode: String) {
        recipientAddress = scannedCode
    }
    
    private func weiToEthString(_ wei: BigUInt, decimals: Int = 18, precision: Int = 6) -> String {
        let divisor = BigUInt(10).power(decimals)
        let (quotient, remainder) = wei.quotientAndRemainder(dividingBy: divisor)
        let remainderString = String(remainder).leftPadding(toLength: decimals, withPad: "0")
        let prefix = "\(quotient)."
        let suffixIndex = remainderString.index(remainderString.startIndex, offsetBy: precision)
        let suffix = remainderString[..<suffixIndex]
        return prefix + suffix
    }
    
    func privateKeyData(fromPasscode passcode: String) -> Data? {
        guard let encryptedData = KeychainManager.shared.read(
            service: KeychainConstants.service,
            account: KeychainConstants.account
        ) else {
            print("No encrypted mnemonic found in Keychain")
            return nil
        }
        
        let key = CryptoManager.key(fromPasscode: passcode)
        
        do {
            let decryptedData = try CryptoManager.decrypt(encryptedData, withKey: key)
            guard let recoveredMnemonic = String(data: decryptedData, encoding: .utf8) else {
                print("Failed to decode mnemonic string")
                return nil
            }
            
            guard let hdWallet = HDWallet(mnemonic: recoveredMnemonic, passphrase: "") else {
                print("Failed to create HDWallet from mnemonic")
                return nil
            }
            
            let key = hdWallet.getKey(
                coin: .ethereum,
                derivationPath: "m/44'/60'/0'/0/0"
            )
            
            return key.data
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    func createKeystore(fromPrivateKey privateKeyData: Data, password: String) throws -> EthereumKeystoreV3? {
        return try EthereumKeystoreV3(privateKey: privateKeyData, password: password) ?? nil
    }
    
    func updateWeb3ForSelectedChain() async {
        guard let chain = chains.first(where: { $0.name == selectedChainName }),
              let url = URL(string: chain.rpcUrl) else {
            errorMessage = "Invalid chain or RPC URL"
            return
        }
        
        
        let network = networkEnum(for: chain.name)
        let provider = await Web3HttpProvider(url, network: network)
        let web3Instance = web3swift.Web3(provider: provider!)
        self.web3 = Web3Network(network: chain, web3: web3Instance)
        
    }
    
    func networkEnum(for chainName: String) -> Networks {
        switch chainName.lowercased() {
        case "ethereum":
            return .Mainnet
        case "binance smart chain":
            return .Custom(networkID: 56)
        case "polygon":
            return .Custom(networkID: 137)
        default:
            return .Mainnet
        }
    }
    
    
}
