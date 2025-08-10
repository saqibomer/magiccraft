//
//  WalletOnboardingView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI
import NotificationBannerSwift

struct WalletOnboardingView: View {
    @EnvironmentObject var appVM: MagicCraftAppViewModel
    @StateObject private var vm = WalletOnboardingViewModel()
    @State private var importMnemonicText = ""
    @State private var passcodeText = ""
    @State private var isImporting = false
    
    var body: some View {
        VStack(spacing: 20) {
            if vm.isUnlocked {
                Text("Wallet Unlocked!")
                    .font(.title)
                    .foregroundColor(.green)
            } else if vm.isWalletCreated {
                Text("Mnemonic:")
                Text(vm.mnemonic)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                SecureField("Enter passcode to encrypt", text: $passcodeText)
                    .textContentType(.password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                Button("Save Wallet") {
                    vm.passcode = passcodeText
                    do {
                        try vm.saveMnemonicToKeychain()
                    } catch {
                        vm.errorMessage = error.localizedDescription
                    }
                }
            } else {
                Button("Create New Wallet") {
                    vm.createNewWallet()
                }
                Button("Import Wallet") {
                    isImporting.toggle()
                }
                if isImporting {
                    TextField("Enter 12-word mnemonic", text: $importMnemonicText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Import") {
                        vm.importWallet(from: importMnemonicText)
                    }
                }
            }
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button("Unlock with Biometrics") {
                vm.unlockWithBiometrics()
            }
        }
        .padding()
        .onReceive(vm.$errorMessage.compactMap { $0 }) { message in
            let banner = NotificationBanner(title: "Error", subtitle: message, style: .danger)
            banner.show()
            vm.errorMessage = nil
        }
        .onReceive(vm.$successMessage.compactMap { $0 }) { message in
            let banner = NotificationBanner(title: "Success", subtitle: message, style: .success)
            banner.show()
            vm.successMessage = nil
        }
        .onAppear {
            vm.onWalletCreated = {
                appVM.walletCreated()
            }
        }
    }
}
