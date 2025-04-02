//
//  CartState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados del carrito
enum CartState {
    case initial
    case loading
    case loaded(Cart)
    case updating
    case error(String)
    case empty
    
    var cart: Cart? {
        if case .loaded(let cart) = self {
            return cart
        }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = self, case .updating = self {
            return true
        }
        return false
    }
    
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        
        if case .loaded(let cart) = self {
            return cart.items.isEmpty
        }
        
        return false
    }
}
