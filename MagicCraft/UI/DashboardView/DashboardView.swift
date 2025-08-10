//
//  DashboardView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init(walletAddress: String) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(walletAddress: walletAddress)!)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading balance...")
                    .padding()
            } else {
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
                                    let apiKey = viewModel.readEtherscanAPIKey() ?? ""
                                    let baseURL = baseURLForChain(token.chainName, action: "txlist")
                                    let explorerPrefix = explorerPrefixForChain(token.chainName)
                                    let chainConfig = ChainAPIConfig(
                                        name: token.chainName,
                                        baseURL: baseURL,
                                        apiKey: apiKey,
                                        explorerPrefix: explorerPrefix
                                    )
                                    
                                    NavigationLink {
                                        TransactionsView(
                                            walletAddress: viewModel.walletAddress.address,
                                            apiKey: apiKey,
                                            chainConfig: chainConfig,
                                            action: "txlist"
                                        )
                                    } label: {
                                        HStack {
                                            Text(token.chainName)
                                            Spacer()
                                            Text("\(token.balance, format: .number) \(token.symbol)")
                                        }
                                    }
                                }
                            }
                            
                            Section(header: Text("MCRT Balances")) {
                                ForEach(viewModel.mcrtBalances) { token in
                                    let apiKey = viewModel.readEtherscanAPIKey() ?? ""
                                    let baseURL = baseURLForChain(token.chainName, action: "tokentx")
                                    let explorerPrefix = explorerPrefixForChain(token.chainName)
                                    let chainConfig = ChainAPIConfig(
                                        name: token.chainName,
                                        baseURL: baseURL,
                                        apiKey: apiKey,
                                        explorerPrefix: explorerPrefix
                                    )
                                    
                                    NavigationLink {
                                        TransactionsView(
                                            walletAddress: viewModel.walletAddress.address,
                                            apiKey: apiKey,
                                            chainConfig: chainConfig,
                                            action: "tokentx"
                                        )
                                    } label: {
                                        HStack {
                                            Text(token.chainName)
                                            Spacer()
                                            Text("\(token.balance, format: .number) \(token.symbol)")
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                    .navigationTitle("Dashboard")
                }
            }
        }
        .task {
            await viewModel.fetchAllBalances()
        }
    }
    
    // Helper to get baseURL for a chain and action
    private func baseURLForChain(_ chainName: String, action: String) -> String {
        switch chainName {
        case "Ethereum":
            return "https://api.etherscan.io/api"
        case "Binance Smart Chain":
            return "https://api.bscscan.com/api"
        case "Polygon":
            return "https://api.polygonscan.com/api"
        default:
            return "https://api.etherscan.io/api" // fallback
        }
    }
    
    // Helper to get explorer URL prefix for a chain
    private func explorerPrefixForChain(_ chainName: String) -> String {
        switch chainName {
        case "Ethereum":
            return "https://etherscan.io/tx/"
        case "Binance Smart Chain":
            return "https://bscscan.com/tx/"
        case "Polygon":
            return "https://polygonscan.com/tx/"
        default:
            return "https://etherscan.io/tx/"
        }
    }
}
