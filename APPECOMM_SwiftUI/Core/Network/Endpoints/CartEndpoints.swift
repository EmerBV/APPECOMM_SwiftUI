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
    case updateItemQuantity(cartId: Int, itemId: Int, quantity: Int)
    case removeItem(cartId: Int, productId: Int)
    
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
        case .updateItemQuantity(let cartId, let itemId, _):
            return "/cartItems/cart/\(cartId)/item/\(itemId)/update"
        case .removeItem(let cartId, let productId):
            return "/cartItems/cart/\(cartId)/item/\(productId)/remove"
        }
    }
    
    var method: String {
        switch self {
        case .getUserCart, .getTotalPrice:
            return HTTPMethod.get.rawValue
        case .clearCart, .removeItem:
            return HTTPMethod.delete.rawValue
        case .addItemToCart:
            return HTTPMethod.post.rawValue
        case .updateItemQuantity:
            return HTTPMethod.put.rawValue
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
            
        case .updateItemQuantity(_, _, let quantity):
            return ["quantity": quantity]
            
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .addItemToCart, .updateItemQuantity:
            return .url
        default:
            return .json
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
