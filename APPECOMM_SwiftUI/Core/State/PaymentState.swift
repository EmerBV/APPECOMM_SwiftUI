//
//  PaymentState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados para el proceso de pago
enum PaymentState {
    case initial
    case preparing
    case ready(clientSecret: String)
    case processing
    case completed(Order)
    case failed(String)
    
    var isLoading: Bool {
        switch self {
        case .preparing, .processing:
            return true
        default:
            return false
        }
    }
    
    var isComplete: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
    var order: Order? {
        if case .completed(let order) = self {
            return order
        }
        return nil
    }
}
