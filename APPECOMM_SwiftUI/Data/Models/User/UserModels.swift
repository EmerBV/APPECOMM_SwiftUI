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
    let orders: [OrderSummary]?
    
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

struct OrderSummary: Codable, Equatable, Identifiable {
    let id: Int
    let orderDate: String
    let status: String
    let totalAmount: Decimal
    let items: [OrderItem]
}

// DTO para enviar detalles de envío a la API
struct ShippingDetailsRequest: Codable, Equatable {
    let id: Int? // ID es opcional para nuevas direcciones, pero requerido para actualizaciones
    let address: String
    let city: String
    let state: String?
    let postalCode: String
    let country: String
    let phoneNumber: String?
    let fullName: String?
    let isDefault: Bool?
    
    static func == (lhs: ShippingDetailsRequest, rhs: ShippingDetailsRequest) -> Bool {
        return lhs.id == rhs.id &&
        lhs.address == rhs.address &&
        lhs.city == rhs.city &&
        lhs.state == rhs.state &&
        lhs.postalCode == rhs.postalCode &&
        lhs.country == rhs.country &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.fullName == rhs.fullName &&
        lhs.isDefault == rhs.isDefault
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case city
        case state
        case postalCode = "postal_code"
        case country
        case phoneNumber = "phone_number"
        case fullName = "full_name"
        case isDefault = "is_default"
    }
}

