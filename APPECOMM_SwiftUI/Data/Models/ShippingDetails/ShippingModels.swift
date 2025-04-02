//
//  ShippingModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

struct ShippingDetails: Codable, Equatable {
    let id: Int?
    let address: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let phoneNumber: String?
    let fullName: String?
}
