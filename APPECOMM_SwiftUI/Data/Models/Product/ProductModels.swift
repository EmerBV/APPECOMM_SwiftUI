//
//  ProductModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

struct Product: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let brand: String
    let price: Decimal
    let inventory: Int
    let description: String?
    let category: Category
    let discountPercentage: Int
    let status: ProductStatus
    let salesCount: Int
    let wishCount: Int
    let preOrder: Bool
    let createdAt: String
    let variants: [Variant]?
    let images: [ImageDto]?
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Category: Codable, Equatable {
    let id: Int
    let name: String
}

struct Variant: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let price: Decimal
    let inventory: Int
}

struct ImageDto: Identifiable, Codable, Equatable {
    let id: Int
    let fileName: String
    let downloadUrl: String
}

enum ProductStatus: String, Codable, Equatable {
    case inStock = "IN_STOCK"
    case outOfStock = "OUT_OF_STOCK"
}
