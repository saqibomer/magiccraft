//
//  CryptoManager.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import CryptoKit

struct CryptoManager {
    static func encrypt(_ plaintext: Data, withKey key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        return sealedBox.combined!
    }

    static func decrypt(_ ciphertext: Data, withKey key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: key)
    }

    static func key(fromPasscode passcode: String) -> SymmetricKey {
        let keyData = SHA256.hash(data: Data(passcode.utf8))
        return SymmetricKey(data: keyData)
    }
}
