//
//  WishListService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation
import Combine

protocol WishListServiceProtocol {
    func getUserWishList(userId: Int) -> AnyPublisher<WishList, NetworkError>
    func addToWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, NetworkError>
    func removeFromWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, NetworkError>
}

final class WishListService: WishListServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getUserWishList(userId: Int) -> AnyPublisher<WishList, NetworkError> {
        let endpoint = WishListEndpoints.getUserWishList(userId: userId)
        Logger.info("WishListService: Fetching wishlist for userId: \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<WishList>.self, endpoint)
            .map { response -> WishList in
                Logger.info("WishListService: Successfully retrieved wishlist with message: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListService: Failed to get wishlist: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func addToWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, NetworkError> {
        let endpoint = WishListEndpoints.addToWishList(userId: userId, productId: productId)
        Logger.info("WishListService: Adding product to wishlist - userId: \(userId), productId: \(productId)")
        
        return networkDispatcher.dispatch(ApiResponse<WishList>.self, endpoint)
            .map { response -> WishList in
                Logger.info("WishListService: Successfully added product to wishlist")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListService: Failed to add product to wishlist: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func removeFromWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, NetworkError> {
        let endpoint = WishListEndpoints.removeFromWishList(userId: userId, productId: productId)
        Logger.info("WishListService: Removing product from wishlist - userId: \(userId), productId: \(productId)")
        
        return networkDispatcher.dispatch(ApiResponse<WishList>.self, endpoint)
            .map { response -> WishList in
                Logger.info("WishListService: Successfully removed product from wishlist")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListService: Failed to remove product from wishlist: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
