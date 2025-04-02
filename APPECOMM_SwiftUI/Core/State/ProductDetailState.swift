//
//  ProductDetailState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados para el detalle de un producto
enum ProductDetailState {
    case initial
    case loading
    case loaded(Product)
    case error(String)
    
    var product: Product? {
        if case .loaded(let product) = self {
            return product
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
