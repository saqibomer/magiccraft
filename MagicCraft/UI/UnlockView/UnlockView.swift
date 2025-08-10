//
//  UnlockView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import SwiftUI

struct UnlockView: View {
    let onUnlock: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Unlock Your Wallet")
                .font(.title)
                .padding(.bottom, 10)
            
            Button(action: onUnlock) {
                Label("Unlock with Biometrics", systemImage: "faceid")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
