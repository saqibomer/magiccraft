//
//  ContentView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    
    @StateObject var appVM = MagicCraftAppViewModel()
    
    var body: some View {
        switch appVM.appState {
        case .onboarding:
            WalletOnboardingView()
                .environmentObject(appVM)
        case .dashboard:
            DashboardView()
        }
        
    }
    
    
}

#Preview {
    ContentView()
}
