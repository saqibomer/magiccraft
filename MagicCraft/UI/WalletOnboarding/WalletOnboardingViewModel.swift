//
//  WalletOnboardingViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import Combine
import WalletCore

class WalletOnboardingViewModel: ObservableObject {
    @Published var mnemonic: String = ""
    @Published var isWalletCreated = false
    @Published var successMessage: String?
    @Published var errorMessage: String?
    @Published var passcode: String = ""

    private var cancellables = Set<AnyCancellable>()
    private let keychainService = KeychainConstants.service
    private let keychainAccount = KeychainConstants.account
    
    var onWalletCreated: (() -> Void)?

    // MARK: - Create new mnemonic
    func createNewWallet(_ apiKey: String) {
        if apiKey == "" {
            errorMessage = "Api key required"
            return
        }
        saveEtherscanAPIKey(apiKey)
        guard let hdWallet = HDWallet(strength: 128, passphrase: "") else {
            errorMessage = "Failed to create wallet"
            return
        }
        mnemonic = hdWallet.mnemonic
        isWalletCreated = true
    }

    // MARK: - Import existing mnemonic
    func importWallet(from mnemonicWords: String, apiKey: String) {
        if apiKey == "" {
            errorMessage = "Api key required"
            return
        }
        saveEtherscanAPIKey(apiKey)
        guard let _ = HDWallet(mnemonic: mnemonicWords, passphrase: "") else {
            errorMessage = "Invalid mnemonic phrase"
            return
        }
        mnemonic = mnemonicWords
        isWalletCreated = true
    }

    // MARK: - Save mnemonic encrypted with passcode to Keychain
    func saveMnemonicToKeychain() throws {
        guard !passcode.isEmpty else {
            errorMessage = "Passcode cannot be empty"
            return
        }
        let key = CryptoManager.key(fromPasscode: passcode)
        guard let mnemonicData = mnemonic.data(using: .utf8) else {
            errorMessage = "Mnemonic encoding error"
            return
        }
        do {
            let encrypted = try CryptoManager.encrypt(mnemonicData, withKey: key)
            let success = KeychainManager.shared.save(encrypted, service: keychainService, account: keychainAccount)
            if success {
                successMessage = "Wallet saved successfully!"
                errorMessage = nil
                onWalletCreated?()
            } else {
                errorMessage = "Failed to save mnemonic"
                successMessage = nil
            }
        } catch {
            errorMessage = "Encryption failed: \(error.localizedDescription)"
            successMessage = nil
        }
    }

    // MARK: - Unlock wallet with passcode
//    func unlockWallet(with passcode: String) throws {
//        guard let encryptedData = KeychainManager.shared.read(service: keychainService, account: keychainAccount) else {
//            errorMessage = "No wallet found"
//            return
//        }
//        let key = CryptoManager.key(fromPasscode: passcode)
//        let decryptedData = try CryptoManager.decrypt(encryptedData, withKey: key)
//        guard let recoveredMnemonic = String(data: decryptedData, encoding: .utf8) else {
//            errorMessage = "Failed to decode mnemonic"
//            return
//        }
//        mnemonic = recoveredMnemonic
//        
//    }

}

extension WalletOnboardingViewModel {
    func saveEtherscanAPIKey(_ apiKey: String) {
        guard let data = apiKey.data(using: .utf8) else {
            errorMessage = "Invalid API key format"
            return
        }
        let success = KeychainManager.shared.save(
            data,
            service: KeychainConstants.etherscanService,
            account: KeychainConstants.etherscanAccount
        )
        if success {
            successMessage = "Etherscan API key saved!"
        } else {
            errorMessage = "Failed to save Etherscan API key"
        }
    }
    
}
