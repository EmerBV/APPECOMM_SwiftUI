//
//  ProductEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

enum ProductEndpoints: APIEndpoint {
    case getAllProducts
    case getProductById(id: Int)
    case getProductsByCategory(category: String)
    case getProductsByBrand(brand: String)
    
    var path: String {
        switch self {
        case .getAllProducts:
            return "/products/all"
        case .getProductById(let id):
            return "/products/product/\(id)/product"
        case .getProductsByCategory(let category):
            return "/products/product/\(category)/all/products"
        case .getProductsByBrand:
            return "/products/product/by-brand"
        }
    }
    
    var method: String {
        return HTTPMethod.get.rawValue
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getProductsByBrand(let brand):
            return ["brand": brand]
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .getProductsByBrand:
            return .url
        default:
            return .json
        }
    }
}
