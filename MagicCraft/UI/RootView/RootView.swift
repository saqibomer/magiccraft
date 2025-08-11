//
//  RootView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI
import NotificationBannerSwift

struct RootView: View {
    @StateObject var appVM = MagicCraftAppViewModel()
    @StateObject var vm = RootViewViewModel()
    
    var body: some View {
        Group {
            if !vm.isUnlocked {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Unlock Your Wallet")
                        .font(.title)
                        .padding(.bottom, 10)
                    Button {
                        vm.unlockWithBiometrics()
                    } label: {
                        Label("Unlock with Biometrics", systemImage: "faceid")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            else if let walletAddress = appVM.walletAddress {
                DashboardView(walletAddress: walletAddress)
                    .onAppear {
                        //                        KeychainManager.shared.delete(
                        //                            service: KeychainConstants.service,
                        //                            account: KeychainConstants.account
                        //                        )
                    }
            }
            else {
                WalletOnboardingView()
                    .environmentObject(appVM)
            }
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

#Preview {
    RootView()
}
