//
//  AppStateViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Combine
import Foundation

enum AppFlowState {
    case onboarding
    case dashboard
}


class MagicCraftAppViewModel: ObservableObject {
    @Published var appState: AppFlowState = .onboarding
    
    private let keychainService = KeychainConstants.service
    private let keychainAccount = KeychainConstants.account
    
    init() {
        checkWalletExistence()
    }
    
    func checkWalletExistence() {
        if let _ = KeychainManager.shared.read(service: keychainService, account: keychainAccount) {
            // Wallet data exists
            appState = .dashboard
        } else {
            // No wallet data
            appState = .onboarding
        }
    }
    
    func walletCreated() {
        appState = .dashboard
    }
}
