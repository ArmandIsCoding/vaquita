//
//  Item.swift
//  Vaquita
//
//  Created by Armando Meabe on 23/03/2026.
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
