//
//  AppStateViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Combine
import Foundation
import WalletCore

enum AppFlowState {
    case onboarding
    case dashboard
}


class MagicCraftAppViewModel: ObservableObject {
    @Published var appState: AppFlowState = .onboarding
    @Published var walletAddress: String? = nil
    
    private let keychainService = KeychainConstants.service
    private let keychainAccount = KeychainConstants.account
    
    init() {
        checkWalletExistence()
    }
    
    func checkWalletExistence() {
        guard let encryptedData = KeychainManager.shared.read(service: keychainService, account: keychainAccount) else {
            return
        }
        let key = CryptoManager.key(fromPasscode: "123123")
        do {
            let decryptedData = try CryptoManager.decrypt(encryptedData, withKey: key)
            guard let recoveredMnemonic = String(data: decryptedData, encoding: .utf8) else {
                return
            }
            let mnemonic = recoveredMnemonic
            guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
                appState = .onboarding
                return
            }
            self.walletAddress = hdWallet.getAddressForCoin(coin: .ethereum)
            appState = .dashboard
            
        } catch {
            print(error)
            appState = .onboarding
        }
    }
    
    func walletCreated(with address: String) {
        walletAddress = address
        appState = .dashboard
    }
}
