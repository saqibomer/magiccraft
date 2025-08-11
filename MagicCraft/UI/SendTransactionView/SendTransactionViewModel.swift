//
//  SendTransactionViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import Foundation
import Combine
import web3swift
import Web3Core
import BigInt
import WalletCore

@MainActor
class SendTransactionViewModel: ObservableObject {
    // Inputs
    @Published var recipient: String = ""
    @Published var amount: String = ""
    @Published var tokenType: TokenType = .native
    
    // Outputs
    @Published var gasEstimate: BigUInt?
    @Published var gasPrice: BigUInt?
    @Published var estimatedFee: Decimal?
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var txHash: String?
    @Published var showConfirmation: Bool = false
    
    // Dependencies
    private let web3: web3swift.Web3
    private let walletAddress: EthereumAddress
    private var keystoreManager: KeystoreManager? = nil
    private let keystorePassword: String
    
    init(web3: web3swift.Web3, walletAddress: EthereumAddress, password: String) {
        self.web3 = web3
        self.walletAddress = walletAddress
        self.keystorePassword = password
        
        // Create KeystoreManager internally:
        if let privateKeyData = self.privateKeyData(fromPasscode: password) {
            do {
                let keystore = try EthereumKeystoreV3(privateKey: privateKeyData, password: password)
                self.keystoreManager = KeystoreManager([keystore!])
                self.web3.addKeystoreManager(self.keystoreManager)
            } catch {
                print("Failed to create keystore: \(error)")
            }
        }
    }
    
    var isInputValid: Bool {
        EthereumAddress(recipient) != nil && (Decimal(string: amount) ?? 0) > 0
    }
    
    func estimateGas() async {
        guard isInputValid else {
            errorMessage = "Invalid address or amount"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        do {
            let toAddress = EthereumAddress(recipient)!
            guard let amountBigUInt = Utilities.parseToBigUInt(amount, units: .ether) else {
                errorMessage = "Invalid amount"
                isLoading = false
                return
            }
            
            var transaction = CodableTransaction.emptyTransaction
            transaction.from = walletAddress
            
            var writeOperation: WriteOperation
            
            switch tokenType {
            case .native:
                transaction.to = toAddress
                transaction.value = amountBigUInt
                
                guard let contract = web3.contract(Web3.Utils.coldWalletABI, at: toAddress, abiVersion: 2) else {
                    throw SendTransactionError.contractError
                }
                contract.transaction = transaction
                
                guard let operation = contract.createWriteOperation("fallback", parameters: []) else {
                    throw SendTransactionError.contractError
                }
                writeOperation = operation
                
            case .erc20(let contractAddress):
                transaction.to = contractAddress
                transaction.value = 0
                
                guard let contract = web3.contract(Web3.Utils.erc20ABI, at: contractAddress, abiVersion: 2) else {
                    throw SendTransactionError.contractError
                }
                contract.transaction = transaction
                
                guard let operation = contract.createWriteOperation(
                    "transfer",
                    parameters: [toAddress as AnyObject, amountBigUInt as AnyObject]
                ) else {
                    throw SendTransactionError.contractError
                }
                writeOperation = operation
            }
            
            // Estimate gas and gas price
            let estimatedGas = try await web3.eth.estimateGas(for: writeOperation.transaction)
            let gasPrice = try await web3.eth.gasPrice()
            
            // Calculate fee in decimal ETH
            let fee = estimatedGas * gasPrice
            let feeDecimal = Decimal(string: fee.description)! / pow(10, 18)
            
            gasEstimate = estimatedGas
            self.gasPrice = gasPrice
            estimatedFee = feeDecimal
            
            showConfirmation = true
            isLoading = false
            
        } catch {
            errorMessage = "Failed to estimate gas: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func sendTransaction() async {
        guard let gasLimit = gasEstimate, let gasPrice = gasPrice else {
            errorMessage = "Gas estimate missing"
            return
        }
        
        isLoading = true
        errorMessage = nil
        txHash = nil
        
        do {
            let toAddress = EthereumAddress(recipient)!
            guard let amountBigUInt = Utilities.parseToBigUInt(amount, units: .ether) else {
                errorMessage = "Invalid amount"
                isLoading = false
                return
            }
            
            var transaction = CodableTransaction.emptyTransaction
            transaction.from = walletAddress
            transaction.gasLimit = gasLimit
            transaction.gasPrice = gasPrice
            
            var writeOperation: WriteOperation
            
            switch tokenType {
            case .native:
                transaction.to = toAddress
                transaction.value = amountBigUInt
                
                guard let contract = web3.contract(Web3.Utils.coldWalletABI, at: toAddress, abiVersion: 2) else {
                    throw SendTransactionError.contractError
                }
                contract.transaction = transaction
                
                guard let operation = contract.createWriteOperation("fallback", parameters: []) else {
                    throw SendTransactionError.contractError
                }
                writeOperation = operation
                
            case .erc20(let contractAddress):
                transaction.to = contractAddress
                transaction.value = 0
                
                guard let contract = web3.contract(Web3.Utils.erc20ABI, at: contractAddress, abiVersion: 2) else {
                    throw SendTransactionError.contractError
                }
                contract.transaction = transaction
                
                guard let operation = contract.createWriteOperation(
                    "transfer",
                    parameters: [toAddress as AnyObject, amountBigUInt as AnyObject]
                ) else {
                    throw SendTransactionError.contractError
                }
                writeOperation = operation
            }
            
            let policies = Policies(
                noncePolicy: .latest,
                gasLimitPolicy: .manual(gasLimit),
                gasPricePolicy: .manual(gasPrice),
                maxFeePerGasPolicy: .automatic,
                maxPriorityFeePerGasPolicy: .automatic
            )
            
            let result = try await writeOperation.writeToChain(
                password: keystorePassword,
                policies: policies
            )
            
            self.txHash = result.hash
            self.isLoading = false
            self.showConfirmation = false
            
        } catch {
            errorMessage = "Transaction failed: \(error.localizedDescription)"
            isLoading = false
        }
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
    
}
