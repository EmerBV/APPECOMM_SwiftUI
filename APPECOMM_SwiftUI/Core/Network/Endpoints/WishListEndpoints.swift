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
            return "/api/wishlist/user/\(userId)"
        case .addToWishList:
            return "/api/wishlist/add"
        case .removeFromWishList(let userId, let productId):
            return "/api/wishlist/user/\(userId)/product/\(productId)"
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
}

