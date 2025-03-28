//
//  OrderModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

// MARK: - Order Model
struct Order: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let orderDate: String
    let totalAmount: Decimal
    let status: String
    let items: [OrderItem]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case orderDate
        case totalAmount
        case status
        case items
    }
    
    static func == (lhs: Order, rhs: Order) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Order Item Model
struct OrderItem: Identifiable, Codable, Equatable {
    let id: Int?
    let productId: Int
    let productName: String
    let productBrand: String
    let variantId: Int?
    let variantName: String?
    let quantity: Int
    let price: Decimal
    let totalPrice: Decimal
    
    var formattedPrice: String {
        return price.toCurrentLocalePrice
    }
    
    var formattedTotalPrice: String {
        return totalPrice.toCurrentLocalePrice
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId
        case productName
        case productBrand
        case variantId
        case variantName
        case quantity
        case price
        case totalPrice
    }
    
    static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        // Use IDs for comparison if available, otherwise full object comparison
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId == rhsId
        }
        return lhs.productId == rhs.productId &&
        lhs.variantId == rhs.variantId &&
        lhs.quantity == rhs.quantity
    }
}
