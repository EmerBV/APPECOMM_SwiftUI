//
//  Product.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

struct Product: Identifiable, Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case id, name, brand, price, inventory, description, category
        case discountPercentage, status, salesCount, wishCount, preOrder, createdAt, variants, images
    }
}
