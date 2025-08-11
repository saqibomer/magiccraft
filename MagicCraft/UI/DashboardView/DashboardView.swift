//
//  DashboardView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var showReceiveView = false
    @State private var showSendView = false

    
    init(walletAddress: String) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(walletAddress: walletAddress)!)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading balance...")
                    .padding()
            }
            else {
                NavigationStack {
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
                                            action: "txlist",
                                            chainID: chainIDForChain(token.chainName)
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
                                        explorerPrefix: explorerPrefix,
                                    )
                                    
                                    NavigationLink {
                                        TransactionsView(
                                            walletAddress: viewModel.walletAddress.address,
                                            apiKey: apiKey,
                                            chainConfig: chainConfig,
                                            action: "tokentx",
                                            chainID: chainIDForChain(token.chainName)
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
                    .navigationDestination(isPresented: $showReceiveView) {
                        ReceiveView(viewModel: ReceiveViewModel(walletAddress: viewModel.walletAddress.address))
                    }
                    .navigationDestination(isPresented: $showSendView) {
                        SendView(viewModel: SendViewModel(walletAddress: viewModel.walletAddress, password: "123123"))
                    }
                    .toolbar {
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                Button {
                                    showReceiveView = true
                                } label: {
                                    Image(systemName: "qrcode")
                                        .imageScale(.large)
                                }
                                Button {
                                    showSendView = true
                                } label: {
                                    Image(systemName: "paperplane.fill") // send icon
                                        .imageScale(.large)
                                }
                            }
                        }
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
            return "https://api.etherscan.io/v2/api"
        case "Binance Smart Chain":
            return "https://api.etherscan.io/v2/api"
        case "Polygon":
            return "https://api.etherscan.io/v2/api"
        default:
            return "https://api.etherscan.io/v2/api" // fallback
        }
    }
    
    // Helper to get explorer URL prefix for a chain
    private func explorerPrefixForChain(_ chainName: String) -> String {
        switch chainName {
        case "Ethereum":
            return "https://api.etherscan.io/v2/tx/"
        case "Binance Smart Chain":
            return "https://api.etherscan.io/v2/tx/"
        case "Polygon":
            return "https://api.etherscan.io/v2/tx/"
        default:
            return "https://api.etherscan.io/v2/tx/"
        }
    }
    
    // Helper to get chainID for Etherscan v2 API (required param)
    private func chainIDForChain(_ chainName: String) -> Int {
        switch chainName {
        case "Ethereum":
            return 1
        case "Binance Smart Chain":
            return 56
        case "Polygon":
            return 137
        default:
            return 1
        }
    }
}
