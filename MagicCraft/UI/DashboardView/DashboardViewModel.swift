//
//  DashboardViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import Combine
import web3swift
import Web3Core
import BigInt

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var nativeBalances: [TokenBalance] = []
    @Published var mcrtBalances: [TokenBalance] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var errorMessage: String?
    
    private let walletAddress: EthereumAddress
    private var networks: [Web3Network] = []
    
    private let chains: [Chain] = [
        Chain(
            name: "Ethereum",
            rpcUrl: "https://mainnet.infura.io/v3/526da39fa0f8458aad9da12c9f5eb7d3",
            nativeSymbol: "ETH",
            mcrtContractAddress: "0xde16ce60804a881e9f8c4ebb3824646edecd478d",
            explorerTxUrlPrefix: "https://etherscan.io/tx/"),
        Chain(
            name: "Binance Smart Chain",
            rpcUrl: "https://bsc-dataseed.binance.org/",
            nativeSymbol: "BNB",
            mcrtContractAddress: "0x4b8285aB433D8f69CB48d5Ad62b415ed1a221e4f",
            explorerTxUrlPrefix: "https://bscscan.com/tx/"),
        Chain(
            name: "Polygon",
            rpcUrl: "https://polygon-rpc.com/",
            nativeSymbol: "MATIC",
            mcrtContractAddress: "",
            explorerTxUrlPrefix: "https://polygonscan.com/tx/")
    ]
    
    // API keys for explorers (you must replace with your own keys)
    private let etherscanAPIKey = "YOUR_ETHERSCAN_API_KEY"
    
    init?(walletAddress: String) {
        guard let ethAddress = EthereumAddress(walletAddress) else {
            self.errorMessage = "Invalid wallet address"
            return nil
        }
        self.walletAddress = ethAddress
    }
    
    func setupNetworks() async {
        var tempNetworks: [Web3Network] = []
        for chain in chains {
            guard let url = URL(string: chain.rpcUrl),
                  let provider = try? await Web3HttpProvider(url: url, network: .Mainnet)
            else { continue }
            let web3 = web3swift.Web3(provider: provider)
            tempNetworks.append(Web3Network(network: chain, web3: web3))
        }
        await MainActor.run {
            self.networks = tempNetworks
        }
    }
    
    func fetchAllBalancesAndTransactions() async {
        await fetchAllBalances()
        await fetchRecentTransactions()
    }
    
    private func fetchAllBalances() async {
        if networks.isEmpty {
            await setupNetworks()
        }
        nativeBalances.removeAll()
        mcrtBalances.removeAll()
        errorMessage = nil
        
        for network in networks {
            do {
                // Native balance
                let nativeBalanceBigUInt = try await network.web3.eth.getBalance(for: walletAddress)
                let nativeBalanceDecimal = formatBalance(nativeBalanceBigUInt)
                let nativeTokenBalance = TokenBalance(
                    chainName: network.network.name,
                    symbol: network.network.nativeSymbol,
                    balance: nativeBalanceDecimal
                )
                nativeBalances.append(nativeTokenBalance)
                
                // MCRT balance
                if !network.network.mcrtContractAddress.isEmpty,
                   let contractAddress = EthereumAddress(network.network.mcrtContractAddress),
                   let contract = network.web3.contract(Web3.Utils.erc20ABI, at: contractAddress),
                   let operation = contract.createReadOperation("balanceOf", parameters: [walletAddress]) {
                    
                    let result = try await operation.callContractMethod()
                    let rawBalance = result["balance"] ?? result["0"]
                    if let balance = rawBalance as? BigUInt {
                        let mcrtBalanceDecimal = formatBalance(balance)
                        let mcrtTokenBalance = TokenBalance(
                            chainName: network.network.name,
                            symbol: "MCRT",
                            balance: mcrtBalanceDecimal
                        )
                        mcrtBalances.append(mcrtTokenBalance)
                    }
                }
            } catch {
                print("Failed to fetch balances for \(network.network.name): \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch balances for \(network.network.name): \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchRecentTransactions() async {
        recentTransactions.removeAll()
        
        let addressString = walletAddress.address
        let explorers: [(name: String, baseURL: String, apiKey: String, prefix: String)] = [
            ("Ethereum", "https://api.etherscan.io/api", etherscanAPIKey, "https://etherscan.io/tx/"),
            ("BSC", "https://api.bscscan.com/api", etherscanAPIKey, "https://bscscan.com/tx/"),
            ("Polygon", "https://api.polygonscan.com/api", etherscanAPIKey, "https://polygonscan.com/tx/")
        ]
        
        for (name, baseURL, apiKey, prefix) in explorers {
            guard !apiKey.isEmpty else {
                print("\(name) API key missing")
                continue
            }
            
            guard let url = URL(string: "\(baseURL)?module=account&action=txlist&address=\(addressString)&startblock=0&endblock=99999999&sort=desc&apikey=\(apiKey)") else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let status = json["status"] as? String, status == "1",
                    let result = json["result"] as? [[String: Any]]
                else {
                    if let message = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                       let errorMsg = message["message"] as? String {
                        print("\(name) API error: \(errorMsg)")
                    }
                    continue
                }
                
                let latestFive = result.prefix(5).compactMap { tx -> Transaction? in
                    guard
                        let hash = tx["hash"] as? String,
                        let from = tx["from"] as? String,
                        let to = tx["to"] as? String,
                        let valueStr = tx["value"] as? String,
                        let timeStampStr = tx["timeStamp"] as? String,
                        let timeStampInt = Double(timeStampStr),
                        let valueBigUInt = BigUInt(valueStr)
                    else { return nil }
                    
                    let date = Date(timeIntervalSince1970: timeStampInt)
                    let valueDecimal = formatBalance(valueBigUInt, decimals: 18) // native coin
                    
                    return Transaction(
                        hash: hash,
                        from: from,
                        to: to,
                        value: valueDecimal,
                        timeStamp: date,
                        explorerUrl: "\(prefix)\(hash)"
                    )
                }
                
                recentTransactions.append(contentsOf: latestFive)
            } catch {
                print("Failed to fetch transactions for \(name): \(error.localizedDescription)")
            }
        }
    }

    
    private func formatBalance(_ balance: BigUInt, decimals: Int = 18) -> Decimal {
        let divisor = BigUInt(10).power(decimals)
        let balanceDecimal = Decimal(string: balance.description) ?? 0
        let divisorDecimal = Decimal(string: divisor.description) ?? 1
        return balanceDecimal / divisorDecimal
    }
}
