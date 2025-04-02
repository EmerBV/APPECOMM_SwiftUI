//
//  OrderListState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados para la lista de pedidos
enum OrderListState {
    case initial
    case loading
    case loaded([Order])
    case error(String)
    case empty
    
    var orders: [Order]? {
        if case .loaded(let orders) = self {
            return orders
        }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        
        if case .loaded(let orders) = self {
            return orders.isEmpty
        }
        
        return false
    }
}
