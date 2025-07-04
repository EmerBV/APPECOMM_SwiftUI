//
//  Double+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 29/4/25.
//

import Foundation

extension Double {
    var toString: String {
        return String(self)
    }
    
    var toPercentage: String {
        return String(format: "%.2f%%", self * 100)
    }
    
    var toDecimals: String {
        return String(format: "%.2f", self)
    }
    
    var toCurrency: String {
        return String(format: "$%.2f", self)
    }
}
