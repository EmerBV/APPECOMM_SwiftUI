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
    let state: String?
    let postalCode: String?
    let country: String?
    let phoneNumber: String?
    let fullName: String?
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
}

// DTO para enviar detalles de envío a la API
struct ShippingDetailsRequest: Codable, Equatable {
    let address: String
    let city: String
    let state: String?
    let postalCode: String
    let country: String
    let phoneNumber: String?
    let fullName: String?
    
    static func == (lhs: ShippingDetailsRequest, rhs: ShippingDetailsRequest) -> Bool {
        return lhs.address == rhs.address &&
        lhs.city == rhs.city &&
        lhs.state == rhs.state &&
        lhs.postalCode == rhs.postalCode &&
        lhs.country == rhs.country &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.fullName == rhs.fullName
    }
}

/// DTO para recibir detalles de envío desde la API
struct ShippingDetailsResponse: Codable, Equatable {
    let id: Int
    let address: String
    let city: String
    let state: String?
    let postalCode: String
    let country: String
    let phoneNumber: String?
    let fullName: String?
    
    static func == (lhs: ShippingDetailsResponse, rhs: ShippingDetailsResponse) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Respuesta de la API que contiene los detalles de envío
struct ApiShippingResponse: Codable {
    let message: String
    let data: ShippingDetailsResponse
}

