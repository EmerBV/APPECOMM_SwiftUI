//
//  Constants.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

enum Constants {
    enum API {
        static let baseURL = "http://localhost:9091/ecommdb/api/v1"
        static let timeout: TimeInterval = 30
    }
    
    enum Formatters {
        static let currencyFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            return formatter
        }()
    }
    
    enum InventoryThresholds {
        static let low = 5
        static let medium = 10
    }
}
