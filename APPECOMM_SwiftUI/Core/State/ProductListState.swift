//
//  ProductListState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

// Estados para la lista de productos
enum ProductListState {
    case initial
    case loading
    case loaded([Product])
    case error(String)
    case empty
    
    var products: [Product]? {
        if case .loaded(let products) = self {
            return products
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
        
        if case .loaded(let products) = self {
            return products.isEmpty
        }
        
        return false
    }
}
