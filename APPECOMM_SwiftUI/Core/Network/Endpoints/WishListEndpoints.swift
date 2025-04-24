//
//  WishListEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

enum WishListEndpoints: APIEndpoint {
    case getUserWishList(userId: Int)
    case addToWishList(userId: Int, productId: Int)
    case removeFromWishList(userId: Int, productId: Int)
    
    var path: String {
        switch self {
        case .getUserWishList(let userId):
            return "/wishlists/user/\(userId)"
        case .addToWishList(let userId, let productId):
            return "/wishlists/user/\(userId)/product/\(productId)/add"
        case .removeFromWishList(let userId, let productId):
            return "/wishlists/user/\(userId)/product/\(productId)/remove"
        }
    }
    
    var method: String {
        switch self {
        case .getUserWishList:
            return HTTPMethod.get.rawValue
        case .addToWishList:
            return HTTPMethod.post.rawValue
        case .removeFromWishList:
            return HTTPMethod.delete.rawValue
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
    
    /*
    var parameters: [String: Any]? {
        switch self {
        case .addToWishList(let userId, let productId):
            return [
                "user_id": userId,
                "product_id": productId
            ]
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .addToWishList:
            return .json
        default :
            return .url
        }
    }
     */
}

