//
//  ShippingAddressesState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import Foundation

enum ShippingAddressesState {
    case initial
    case loading
    case loaded([ShippingDetailsResponse])
    case error(String)
    case empty
    
    var addresses: [ShippingDetailsResponse]? {
        if case .loaded(let addresses) = self {
            return addresses
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
        
        if case .loaded(let addresses) = self {
            return addresses.isEmpty
        }
        
        return false
    }
    
    var defaultAddress: ShippingDetailsResponse? {
        if case .loaded(let addresses) = self {
            return addresses.first(where: { $0.isDefault == true })
        }
        return nil
    }
}
