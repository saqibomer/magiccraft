//
//  DashboardView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init(walletAddress: String) {
            // Initialize without async
        _viewModel = StateObject(wrappedValue: DashboardViewModel(walletAddress: walletAddress)!)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                List {
                    Section(header: Text("Native Balances")) {
                        ForEach(viewModel.nativeBalances) { token in
                            HStack {
                                Text(token.chainName)
                                Spacer()
                                Text("\(token.balance, format: .number) \(token.symbol)")
                            }
                        }
                    }
                    
                    Section(header: Text("MCRT Balances")) {
                        ForEach(viewModel.mcrtBalances) { token in
                            HStack {
                                Text(token.chainName)
                                Spacer()
                                Text("\(token.balance, format: .number) \(token.symbol)")
                            }
                        }
                    }
                }
                ForEach(viewModel.recentTransactions) { tx in
                    Link(tx.hash, destination: URL(string: tx.explorerUrl)!)
                }

            }
            .navigationTitle("Dashboard")
            .task {
                // Refresh balances on appear
                await viewModel.fetchAllBalancesAndTransactions()
            }
        }
    }
}

