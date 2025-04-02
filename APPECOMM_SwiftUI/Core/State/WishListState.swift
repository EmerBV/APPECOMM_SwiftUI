//
//  WishListState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

/// Estados de la lista de deseos
enum WishListState {
    case initial
    case loading
    case loaded(WishList)
    case updating
    case error(String)
    case empty
    
    var wishList: WishList? {
        if case .loaded(let wishList) = self {
            return wishList
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
        
        if case .loaded(let wishList) = self {
            return wishList.products.isEmpty
        }
        
        return false
    }
}
