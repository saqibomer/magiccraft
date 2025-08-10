//
//  Web3Network.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import web3swift
import BigInt

class Web3Network {
    let network: Chain
    let web3: Web3
    var tokensBalances: [String: BigUInt] = [:]
    
    init(network: Chain, web3: Web3) {
        self.network = network
        self.web3 = web3
    }
}
