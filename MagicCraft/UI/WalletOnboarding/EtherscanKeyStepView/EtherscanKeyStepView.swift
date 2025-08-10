//
//  EtherscanKeyStepView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI

struct EtherscanKeyStepView: View {
    @Binding var apiKey: String
    
    var body: some View {
        GroupBox(label: Label("Step 1: Etherscan API Key", systemImage: "key.fill")) {
            VStack(alignment: .leading, spacing: 12) {
                Text("To fetch blockchain data, we need your Etherscan API key.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                Link("Don't have an API key? Get one here →", destination: URL(string: "https://etherscan.io/apidashboard")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
        }
    }
}



