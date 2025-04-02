//
//  CartRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol CartRepositoryProtocol {
    var cartState: CurrentValueSubject<CartState, Never> { get }
    
    func getUserCart(userId: Int) -> AnyPublisher<Cart, Error>
    func clearCart(cartId: Int) -> AnyPublisher<Void, Error>
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, Error>
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, Error>
    func updateItemQuantity(cartId: Int, itemId: Int, quantity: Int) -> AnyPublisher<Void, Error>
    func removeItem(cartId: Int, itemId: Int) -> AnyPublisher<Void, Error>
    func refreshCart(userId: Int) -> AnyPublisher<Cart, Error>
    
    func debugCartState()
}

final class CartRepository: CartRepositoryProtocol {
    var cartState: CurrentValueSubject<CartState, Never> = CurrentValueSubject(.initial)
    
    private let cartService: CartServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(cartService: CartServiceProtocol) {
        self.cartService = cartService
    }
    
    func getUserCart(userId: Int) -> AnyPublisher<Cart, Error> {
        Logger.info("CartRepository: Getting cart for user: \(userId)")
        cartState.send(.loading)
        
        return cartService.getUserCart(userId: userId)
            .handleEvents(receiveOutput: { [weak self] cart in
                Logger.info("CartRepository: Received cart with \(cart.items.count) items")
                if cart.items.isEmpty {
                    self?.cartState.send(.empty)
                } else {
                    self?.cartState.send(.loaded(cart))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CartRepository: Failed to get cart: \(error)")
                    self?.cartState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func clearCart(cartId: Int) -> AnyPublisher<Void, Error> {
        Logger.info("CartRepository: Clearing cart: \(cartId)")
        cartState.send(.updating)
        
        return cartService.clearCart(cartId: cartId)
            .handleEvents(receiveOutput: { [weak self] _ in
                Logger.info("CartRepository: Cart cleared successfully")
                self?.cartState.send(.empty)
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CartRepository: Failed to clear cart: \(error)")
                    self?.cartState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getTotalPrice(cartId: Int) -> AnyPublisher<Decimal, Error> {
        Logger.info("CartRepository: Getting total price for cart: \(cartId)")
        
        return cartService.getTotalPrice(cartId: cartId)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func addItemToCart(productId: Int, quantity: Int, variantId: Int?) -> AnyPublisher<Void, Error> {
        Logger.info("CartRepository: Adding item to cart - productId: \(productId), quantity: \(quantity), variantId: \(variantId ?? -1)")
        cartState.send(.updating)
        
        return cartService.addItemToCart(productId: productId, quantity: quantity, variantId: variantId)
            .mapError { $0 as Error } // Convertir NetworkError a Error
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                Logger.info("CartRepository: Item added to cart, refreshing cart")
                
                // Obtener el ID del usuario
                guard let self = self else {
                    return Fail(error: NSError(domain: "CartRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"]))
                        .eraseToAnyPublisher()
                }
                
                guard let userId = TokenManager.shared.getUserId() else {
                    return Fail(error: NSError(domain: "CartRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
                        .eraseToAnyPublisher()
                }
                
                // Refrescar el carrito después de añadir un artículo
                return self.refreshCart(userId: userId)
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CartRepository: Failed to add item to cart: \(error)")
                    // Intentar recuperar el estado anterior del carrito
                    self?.refreshCartAfterError()
                }
            })
            .eraseToAnyPublisher()
    }
    
    func updateItemQuantity(cartId: Int, itemId: Int, quantity: Int) -> AnyPublisher<Void, Error> {
        Logger.info("CartRepository: Updating item quantity - cartId: \(cartId), itemId: \(itemId), quantity: \(quantity)")
        cartState.send(.updating)
        
        return cartService.updateItemQuantity(cartId: cartId, itemId: itemId, quantity: quantity)
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                Logger.info("CartRepository: Item quantity updated, refreshing cart")
                
                guard let self = self else {
                    return Fail(error: NSError(domain: "CartRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"]))
                        .eraseToAnyPublisher()
                }
                
                // Obtener el ID del usuario desde el token
                guard let userId = TokenManager.shared.getUserId() else {
                    return Fail(error: NSError(domain: "CartRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
                        .eraseToAnyPublisher()
                }
                
                // Refrescar el carrito después de actualizar un artículo
                return self.refreshCart(userId: userId)
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CartRepository: Failed to update item quantity: \(error)")
                    // Intentar recuperar el estado anterior del carrito
                    self?.refreshCartAfterError()
                }
            })
            .eraseToAnyPublisher()
    }
    
    func removeItem(cartId: Int, itemId: Int) -> AnyPublisher<Void, Error> {
        Logger.info("CartRepository: Removing item from cart - cartId: \(cartId), itemId: \(itemId)")
        cartState.send(.updating)
        
        return cartService.removeItem(cartId: cartId, itemId: itemId)
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                Logger.info("CartRepository: Item removed from cart, refreshing cart")
                
                guard let self = self else {
                    return Fail(error: NSError(domain: "CartRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"]))
                        .eraseToAnyPublisher()
                }
                
                // Obtener el ID del usuario desde el token
                guard let userId = TokenManager.shared.getUserId() else {
                    return Fail(error: NSError(domain: "CartRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
                        .eraseToAnyPublisher()
                }
                
                // Refrescar el carrito después de eliminar un artículo
                return self.refreshCart(userId: userId)
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CartRepository: Failed to remove item from cart: \(error)")
                    // Intentar recuperar el estado anterior del carrito
                    self?.refreshCartAfterError()
                }
            })
            .eraseToAnyPublisher()
    }
    
    func refreshCart(userId: Int) -> AnyPublisher<Cart, Error> {
        Logger.info("CartRepository: Refreshing cart for user: \(userId)")
        
        return cartService.getUserCart(userId: userId)
            .handleEvents(receiveOutput: { [weak self] cart in
                Logger.info("CartRepository: Cart refreshed with \(cart.items.count) items")
                if cart.items.isEmpty {
                    self?.cartState.send(.empty)
                } else {
                    self?.cartState.send(.loaded(cart))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CartRepository: Failed to refresh cart: \(error)")
                    self?.cartState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func refreshCartAfterError() {
        // Obtener el ID del usuario desde el token
        if let userId = TokenManager.shared.getUserId() {
            cartService.getUserCart(userId: userId)
                .sink(receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        Logger.error("CartRepository: Failed to recover cart state: \(error)")
                        self?.cartState.send(.error(error.localizedDescription))
                    }
                }, receiveValue: { [weak self] cart in
                    if cart.items.isEmpty {
                        self?.cartState.send(.empty)
                    } else {
                        self?.cartState.send(.loaded(cart))
                    }
                })
                .store(in: &cancellables)
        } else {
            // No hay usuario autenticado, no podemos recuperar el carrito
            cartState.send(.error("No hay usuario autenticado"))
        }
    }
    
    func debugCartState() {
        Logger.debug("Current cart state: \(cartState.value)")
        
        if case .loaded(let cart) = cartState.value {
            Logger.debug("Cart ID: \(cart.cartId), Total Items: \(cart.items.count), Total Amount: \(cart.totalAmount)")
            for item in cart.items {
                Logger.debug("Item ID: \(item.itemId), Product: \(item.product.name), Quantity: \(item.quantity), Total: \(item.totalPrice)")
            }
        }
    }
}

