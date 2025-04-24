//
//  WishListModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

struct WishList: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let products: [Product]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case products
    }
    
    static func == (lhs: WishList, rhs: WishList) -> Bool {
        return lhs.id == rhs.id
    }
}
