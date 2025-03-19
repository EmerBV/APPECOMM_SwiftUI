//
//  CartEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

enum CartEndpoints: APIEndpoint {
    case getUserCart(userId: Int)
    case clearCart(cartId: Int)
    case getTotalPrice(cartId: Int)
    case addItemToCart(productId: Int, quantity: Int, variantId: Int?)
    
    var path: String {
        switch self {
        case .getUserCart(let userId):
            return "/carts/user/\(userId)/my-cart"
        case .clearCart(let cartId):
            return "/carts/\(cartId)/clear"
        case .getTotalPrice(let cartId):
            return "/carts/\(cartId)/cart/total-price"
        case .addItemToCart:
            return "/cartItems/item/add"
        }
    }
    
    var method: String {
        switch self {
        case .getUserCart, .getTotalPrice:
            return HTTPMethod.get.rawValue
        case .clearCart:
            return HTTPMethod.delete.rawValue
        case .addItemToCart:
            return HTTPMethod.post.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .addItemToCart(let productId, let quantity, let variantId):
            var params: [String: Any] = [
                "productId": productId,
                "quantity": quantity
            ]
            
            if let variantId = variantId {
                params["variantId"] = variantId
            }
            
            return params
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .addItemToCart:
            return .url  // Esta API usa query params en lugar de JSON
        default:
            return .json
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
