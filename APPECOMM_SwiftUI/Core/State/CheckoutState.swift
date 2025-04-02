//
//  CheckoutState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados para el proceso de checkout
enum CheckoutState {
    case initial
    case shippingDetails
    case paymentMethod
    case orderSummary
    case processing
    case completed(Order)
    case failed(String)
    
    var isComplete: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = self {
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
