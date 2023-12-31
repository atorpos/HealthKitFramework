//
//  Item.swift
//  HealthKitFramework
//
//  Created by Oskar Wong on 2023-10-13.
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
