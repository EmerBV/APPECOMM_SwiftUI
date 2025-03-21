//
//  CartRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol CartRepositoryProtocol {
    func getUserCart(userId: Int) -> AnyPublisher<Cart, Error>
    func clearCart(cartId: Int) -> AnyPublisher<Void, Error>
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, Error>
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, Error>
    func updateItemQuantity(cartId: Int, itemId: Int, quantity: Int) -> AnyPublisher<Void, Error>
    func removeItem(cartId: Int, itemId: Int) -> AnyPublisher<Void, Error>
}

final class CartRepository: CartRepositoryProtocol {
    private let cartService: CartServiceProtocol
    
    init(cartService: CartServiceProtocol) {
        self.cartService = cartService
    }
    
    func getUserCart(userId: Int) -> AnyPublisher<Cart, Error> {
        return cartService.getUserCart(userId: userId)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func clearCart(cartId: Int) -> AnyPublisher<Void, Error> {
        return cartService.clearCart(cartId: cartId)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, Error> {
        return cartService.getTotalPrice(cartId: cartId)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, Error> {
        return cartService.addItemToCart(productId: productId, quantity: quantity, variantId: variantId)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateItemQuantity(cartId: Int, itemId: Int, quantity: Int) -> AnyPublisher<Void, Error> {
        return cartService.updateItemQuantity(cartId: cartId, itemId: itemId, quantity: quantity)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func removeItem(cartId: Int, itemId: Int) -> AnyPublisher<Void, Error> {
        return cartService.removeItem(cartId: cartId, itemId: itemId)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
