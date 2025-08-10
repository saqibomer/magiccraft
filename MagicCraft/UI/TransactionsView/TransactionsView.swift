//
//  TransactionsView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI

struct TransactionsView: View {
    @StateObject private var vm: TransactionsViewModel
    
    init(walletAddress: String, apiKey: String, chainConfig: ChainAPIConfig, action: String = "txlist") {
        _vm = StateObject(wrappedValue: TransactionsViewModel(walletAddress: walletAddress, apiKey: apiKey, chainConfig: chainConfig, action: action))
    }
    
    var body: some View {
        VStack {
            if vm.isLoading {
                ProgressView("Loading transactions...")
                    .padding()
            } else if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if vm.transactions.isEmpty {
                Text("No transactions found.")
                    .padding()
            } else {
                List(vm.transactions) { tx in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hash: \(tx.hash)")
                            .font(.footnote)
                            .lineLimit(1)
                        Text("From: \(tx.from)")
                            .font(.caption)
                            .lineLimit(1)
                        Text("To: \(tx.to)")
                            .font(.caption)
                            .lineLimit(1)
                        Text("Value: \(tx.value.description)")
                            .font(.caption)
                        Text("Date: \(tx.timeStamp.formatted(date: .numeric, time: .shortened))")
                            .font(.caption2)
                        Link("View on Explorer", destination: URL(string: tx.explorerUrl)!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(4)
                }
            }
        }
        .navigationTitle("\(vm.chainConfig.name) Transactions")
        .task {
            await vm.fetchTransactions()
        }
    }
}
