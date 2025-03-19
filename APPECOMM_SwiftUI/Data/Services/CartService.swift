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
        return networkDispatcher.dispatch(endpoint)
    }
    
    func clearCart(cartId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.clearCart(cartId: cartId)
        return networkDispatcher.dispatchData(endpoint)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, NetworkError> {
        let endpoint = CartEndpoints.getTotalPrice(cartId: cartId)
        return networkDispatcher.dispatch(endpoint)
    }
    
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, NetworkError> {
        let endpoint = CartEndpoints.addItemToCart(
            productId: productId,
            quantity: quantity,
            variantId: variantId
        )
        return networkDispatcher.dispatchData(endpoint)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
