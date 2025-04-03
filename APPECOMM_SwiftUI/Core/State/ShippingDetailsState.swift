//
//  ShippingDetailsState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

enum ShippingDetailsState {
    case initial
    case loading
    case loaded(ShippingDetails)
    case error(String)
    case empty
}
