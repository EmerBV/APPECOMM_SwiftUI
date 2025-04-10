//
//  CartModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

struct Cart: Identifiable, Codable, Equatable {
    let cartId: Int
    let items: [CartItem]
    let totalAmount: Decimal
    
    var id: Int { return cartId }
    
    static func == (lhs: Cart, rhs: Cart) -> Bool {
        return lhs.cartId == rhs.cartId
    }
}

struct CartItem: Identifiable, Codable, Equatable {
    let itemId: Int
    let quantity: Int
    let unitPrice: Decimal
    let totalPrice: Decimal
    let variantId: Int?
    let variantName: String?
    let product: CartProductDto
    
    var id: Int { return itemId }
    
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.itemId == rhs.itemId
    }
}

struct CartProductDto: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let brand: String
    let price: Decimal
    let images: [ProductImage]?
    
    static func == (lhs: CartProductDto, rhs: CartProductDto) -> Bool {
        return lhs.id == rhs.id
    }
}
