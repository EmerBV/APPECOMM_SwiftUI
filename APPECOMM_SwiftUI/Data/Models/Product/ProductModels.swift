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
    let createdAt: String  // Asegurarnos de que esto sea String para la fecha
    let variants: [Variant]?
    let images: [ProductImage]?
    
    // Añadir CodingKeys solo si los nombres no coinciden exactamente
    enum CodingKeys: String, CodingKey {
        case id, name, brand, price, inventory, description, category
        case discountPercentage, status, salesCount, wishCount, preOrder, createdAt, variants, images
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Variant: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let price: Decimal
    let inventory: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, inventory
    }
    
    static func == (lhs: Variant, rhs: Variant) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ProductImage: Identifiable, Codable, Equatable {
    let id: Int
    let fileName: String
    let downloadUrl: String
}

enum ProductStatus: String, Codable, Equatable, CaseIterable {
    case inStock = "IN_STOCK"
    case outOfStock = "OUT_OF_STOCK"
    
    var displayName: String {
        switch self {
        case .inStock:
            return NSLocalizedString("product_status_in_stock", comment: "Product status: in stock")
        case .outOfStock:
            return NSLocalizedString("product_status_out_of_stock", comment: "Product status: out of stock")
        }
    }
    
    var color: String {
        switch self {
        case .inStock:
            return "StatusGreen"
        case .outOfStock:
            return "StatusRed"
        }
    }
}
