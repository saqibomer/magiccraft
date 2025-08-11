//
//  SendTransactionInput.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//
import Web3Core
import Foundation

struct SendTransactionInput {
    let recipient: EthereumAddress
    let amount: Decimal // amount in tokens (e.g. 0.01 ETH or 10 MCRT)
    let tokenType: TokenType // .native or .erc20
}
