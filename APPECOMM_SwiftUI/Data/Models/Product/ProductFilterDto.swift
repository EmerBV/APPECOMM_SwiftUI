//
//  ProductFilterDto.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/5/25.
//

import Foundation

struct ProductFilterDto {
    let sortBy: String?
    let availability: ProductStatus?
    let category: String?
    let minPrice: Decimal?
    let maxPrice: Decimal?
    let brand: String?
    let page: Int
    let size: Int
}
