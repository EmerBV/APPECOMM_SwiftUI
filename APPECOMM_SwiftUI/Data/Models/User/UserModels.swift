//
//  UserModels.swift
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
    let shippingDetails: [ShippingDetails]?
    let cart: CartSummary?
    let orders: [Order]?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CartSummary: Codable, Equatable {
    let id: Int?
    let totalAmount: Decimal?
    
    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount = "total_amount"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        totalAmount = try container.decodeIfPresent(Decimal.self, forKey: .totalAmount)
    }
}

// DTO para enviar detalles de envío a la API
struct ShippingDetailsRequest: Codable {
    let id: Int?
    let address: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let phoneNumber: String
    let fullName: String
    let isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case city
        case state
        case postalCode = "postalCode"
        case country
        case phoneNumber = "phoneNumber"
        case fullName = "fullName"
        case isDefault = "isDefault"
    }
}

