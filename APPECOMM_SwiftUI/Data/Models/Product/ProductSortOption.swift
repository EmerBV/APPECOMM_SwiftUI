//
//  ProductSortOption.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/5/25.
//

import Foundation
import Combine

enum ProductSortOption: String, CaseIterable, Identifiable {
    case newest = "newest"
    case priceAsc = "price_asc"
    case priceDesc = "price_desc"
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case bestSelling = "bestselling"
    case mostWished = "mostwished"
    case discount = "discount"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .newest: return "newest".localized
        case .priceAsc: return "price_low_to_high".localized
        case .priceDesc: return "price_high_to_low".localized
        case .nameAsc: return "name_a_to_z".localized
        case .nameDesc: return "name_z_to_a".localized
        case .bestSelling: return "best_selling".localized
        case .mostWished: return "most_wished".localized
        case .discount: return "biggest_discount".localized
        }
    }
}

struct ProductFilter {
    var sortBy: ProductSortOption? = .newest
    var minPrice: Decimal? = nil
    var maxPrice: Decimal? = nil
    var availability: ProductStatus? = nil
    var selectedCategory: String? = nil
    var selectedBrand: String? = nil
    
    // Helper function to check if any filter besides default sorting is applied
    var hasActiveFilters: Bool {
        return minPrice != nil || maxPrice != nil || availability != nil ||
        selectedCategory != nil || selectedBrand != nil || sortBy != .newest
    }
    
    // Reset all filters to default values
    mutating func reset() {
        sortBy = .newest
        minPrice = nil
        maxPrice = nil
        availability = nil
        selectedCategory = nil
        selectedBrand = nil
    }
}
