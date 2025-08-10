//
//  Item.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
