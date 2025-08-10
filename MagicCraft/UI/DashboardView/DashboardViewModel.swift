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
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    let walletAddress: EthereumAddress
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

    
    func fetchAllBalances() async {
        if networks.isEmpty {
            await setupNetworks()
        }
        nativeBalances.removeAll()
        mcrtBalances.removeAll()
        errorMessage = nil
        isLoading = true
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
        isLoading = false
    }
    
    func readEtherscanAPIKey() -> String? {
        if let data = KeychainManager.shared.read(
            service: KeychainConstants.etherscanService,
            account: KeychainConstants.etherscanAccount
        ) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func formatBalance(_ balance: BigUInt, decimals: Int = 18) -> Decimal {
        let divisor = BigUInt(10).power(decimals)
        let balanceDecimal = Decimal(string: balance.description) ?? 0
        let divisorDecimal = Decimal(string: divisor.description) ?? 1
        return balanceDecimal / divisorDecimal
    }
}
