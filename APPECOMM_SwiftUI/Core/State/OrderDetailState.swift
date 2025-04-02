//
//  OrderDetailState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados para el detalle de un pedido
enum OrderDetailState {
    case initial
    case loading
    case loaded(Order)
    case error(String)
    
    var order: Order? {
        if case .loaded(let order) = self {
            return order
        }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}
