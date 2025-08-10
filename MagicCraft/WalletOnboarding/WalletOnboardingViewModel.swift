//
//  WalletOnboardingViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import Combine
import WalletCore
import LocalAuthentication

class WalletOnboardingViewModel: ObservableObject {
    @Published var mnemonic: String = ""
    @Published var isWalletCreated = false
    @Published var isUnlocked = false
    @Published var errorMessage: String?
    @Published var passcode: String = ""

    private var cancellables = Set<AnyCancellable>()
    private let keychainService = "com.kaboomlab.MagicCraft"
    private let keychainAccount = "mnemonic"

    // MARK: - Create new mnemonic
    func createNewWallet() {
        guard let hdWallet = HDWallet(strength: 128, passphrase: "") else {
            errorMessage = "Failed to create wallet"
            return
        }
        mnemonic = hdWallet.mnemonic
        isWalletCreated = true
    }

    // MARK: - Import existing mnemonic
    func importWallet(from mnemonicWords: String) {
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
        let encrypted = try CryptoManager.encrypt(mnemonicData, withKey: key)
        let success = KeychainManager.shared.save(encrypted, service: keychainService, account: keychainAccount)
        if !success {
            errorMessage = "Failed to save mnemonic"
        }
    }

    // MARK: - Unlock wallet with passcode
    func unlockWallet(with passcode: String) throws {
        guard let encryptedData = KeychainManager.shared.read(service: keychainService, account: keychainAccount) else {
            errorMessage = "No wallet found"
            return
        }
        let key = CryptoManager.key(fromPasscode: passcode)
        let decryptedData = try CryptoManager.decrypt(encryptedData, withKey: key)
        guard let recoveredMnemonic = String(data: decryptedData, encoding: .utf8) else {
            errorMessage = "Failed to decode mnemonic"
            return
        }
        mnemonic = recoveredMnemonic
        isUnlocked = true
    }

    // MARK: - Unlock wallet with biometrics
    func unlockWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your wallet") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        self.errorMessage = "Biometric authentication failed"
                    }
                }
            }
        } else {
            errorMessage = "Biometrics not available"
        }
    }
}
