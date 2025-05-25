//
//  Item.swift
//  Keeper
//
//  Created by Jeremy Kim on 5/24/25.
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
