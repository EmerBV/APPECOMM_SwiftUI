//
//  User.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let shippingDetails: ShippingDetails?
    let cart: CartSummary?
    let orders: [OrderSummary]?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ShippingDetails: Codable, Equatable {
    let id: Int?
    let address: String?
    let city: String?
    let postalCode: String?
    let country: String?
    let phoneNumber: String?
}

struct CartSummary: Codable, Equatable {
    let id: Int
    let totalAmount: Decimal
}

struct OrderSummary: Codable, Equatable, Identifiable {
    let id: Int
    let orderDate: String
    let status: String
    let totalAmount: Decimal
}
