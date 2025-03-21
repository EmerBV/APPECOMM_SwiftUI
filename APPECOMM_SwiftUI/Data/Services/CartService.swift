//
//  CartService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol CartServiceProtocol {
    func getUserCart(userId: Int) -> AnyPublisher<Cart, NetworkError>
    func clearCart(cartId: Int) -> AnyPublisher<Void, NetworkError>
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, NetworkError>
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, NetworkError>
    func updateItemQuantity(cartId: Int, itemId: Int, quantity: Int) -> AnyPublisher<Void, NetworkError>
    func removeItem(cartId: Int, itemId: Int) -> AnyPublisher<Void, NetworkError>
}

final class CartService: CartServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getUserCart(userId: Int) -> AnyPublisher<Cart, NetworkError> {
        let endpoint = CartEndpoints.getUserCart(userId: userId)
        Logger.info("CartService: Fetching cart for userId: \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<Cart>.self, endpoint)
            .map { response -> Cart in
                Logger.info("CartService: Successfully retrieved cart with message: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CartService: Failed to get cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func clearCart(cartId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.clearCart(cartId: cartId)
        Logger.info("CartService: Clearing cart with ID: \(cartId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("CartService: Successfully cleared cart")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CartService: Failed to clear cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, NetworkError> {
        let endpoint = CartEndpoints.getTotalPrice(cartId: cartId)
        Logger.info("CartService: Getting total price for cartId: \(cartId)")
        
        return networkDispatcher.dispatch(ApiResponse<Decimal>.self, endpoint)
            .map { response -> Decimal in
                Logger.info("CartService: Successfully got total price")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CartService: Failed to get total price: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.addItemToCart(productId: productId, quantity: quantity, variantId: variantId)
        Logger.info("CartService: Adding item to cart - productId: \(productId), quantity: \(quantity), variantId: \(variantId ?? -1)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("CartService: Successfully added item to cart")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CartService: Failed to add item to cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func updateItemQuantity(cartId: Int, itemId: Int, quantity: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.updateItemQuantity(cartId: cartId, itemId: itemId, quantity: quantity)
        Logger.info("CartService: Updating cart item quantity - cartId: \(cartId), itemId: \(itemId), quantity: \(quantity)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("CartService: Successfully updated item quantity")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CartService: Failed to update item quantity: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func removeItem(cartId: Int, itemId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.removeItem(cartId: cartId, itemId: itemId)
        Logger.info("CartService: Removing item from cart - cartId: \(cartId), itemId: \(itemId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("CartService: Successfully removed item from cart")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CartService: Failed to remove item from cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
