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
    @State private var etherscanAPIKey = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TitleHeaderView()
                EtherscanKeyStepView(apiKey: $etherscanAPIKey)
                Divider()
                if vm.isWalletCreated {
                    WalletCreatedView(
                        mnemonic: vm.mnemonic,
                        passcode: $passcodeText,
                        onSave: {
                            vm.passcode = passcodeText
                            do {
                                try vm.saveMnemonicToKeychain()
                                appVM.appState = .dashboard
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    )
                } else {
                    WalletSetupStepView(
                        isImporting: $isImporting,
                        importMnemonic: $importMnemonicText,
                        onCreate: { vm.createNewWallet(etherscanAPIKey) },
                        onImport: { vm.importWallet(from: importMnemonicText, apiKey: etherscanAPIKey) }
                    )
                }
                
            }
            .padding()
        }
        .onReceive(vm.$errorMessage.compactMap { $0 }) { message in
            NotificationBanner(title: "Error", subtitle: message, style: .danger).show()
            vm.errorMessage = nil
        }
        .onReceive(vm.$successMessage.compactMap { $0 }) { message in
            NotificationBanner(title: "Success", subtitle: message, style: .success).show()
            vm.successMessage = nil
        }
    }
}
