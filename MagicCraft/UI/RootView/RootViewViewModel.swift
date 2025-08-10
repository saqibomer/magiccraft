//
//  RootViewViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import Combine
import LocalAuthentication

class RootViewViewModel: ObservableObject {
    @Published var isUnlocked = false
    @Published var successMessage: String?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let keychainService = KeychainConstants.service
    private let keychainAccount = KeychainConstants.account
    
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

