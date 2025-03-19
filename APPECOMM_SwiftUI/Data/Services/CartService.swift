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
}

final class CartService: CartServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getUserCart(userId: Int) -> AnyPublisher<Cart, NetworkError> {
        let endpoint = CartEndpoints.getUserCart(userId: userId)
        print("CartService: Fetching cart for userId: \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<Cart>.self, endpoint)
            .map { response -> Cart in
                print("CartService: Successfully retrieved cart with message: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("CartService: Failed to get cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func clearCart(cartId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.clearCart(cartId: cartId)
        print("CartService: Clearing cart with ID: \(cartId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                print("CartService: Successfully cleared cart")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("CartService: Failed to clear cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Para respuestas donde el dato es un valor simple como Decimal
    struct DecimalWrapper: Codable {
        let value: Decimal
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Decimal.self)
        }
    }
    
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, NetworkError> {
        let endpoint = CartEndpoints.getTotalPrice(cartId: cartId)
        print("CartService: Getting total price for cartId: \(cartId)")
        
        return networkDispatcher.dispatch(ApiResponse<Decimal>.self, endpoint)
            .map { response -> Decimal in
                print("CartService: Successfully got total price")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("CartService: Failed to get total price: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.addItemToCart(productId: productId, quantity: quantity, variantId: variantId)
        print("CartService: Adding item to cart - productId: \(productId), quantity: \(quantity), variantId: \(variantId ?? -1)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                print("CartService: Successfully added item to cart")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("CartService: Failed to add item to cart: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
