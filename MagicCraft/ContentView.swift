//
//  ContentView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import SwiftUI
import SwiftData

//struct ContentView: View {
//    @StateObject var appVM = MagicCraftAppViewModel()
//
//    var body: some View {
//        Group {
//            if !appVM.isBiometricUnlocked {
//                UnlockView(onUnlock: appVM.unlockWithBiometrics)
//                    .environmentObject(appVM)
//            }
//            else if let walletAddress = appVM.walletAddress {
//                DashboardView(walletAddress: walletAddress)
//                    .onAppear {
////                        KeychainManager.shared.delete(
////                            service: KeychainConstants.service,
////                            account: KeychainConstants.account
////                        )
//                    }
//            }
//            else {
//                WalletOnboardingView()
//                    .environmentObject(appVM)
//            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
