//
//  CartViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 21/3/25.
//

import Foundation
import Combine

class CartViewModel: ObservableObject {
    // Published properties
    @Published var cart: Cart?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Cart state
    @Published var isUpdatingCart = false
    @Published var isRemovingItem = false
    @Published var isProcessingCheckout = false
    
    // Dependencies
    private let cartRepository: CartRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Auth state accessor
    var isUserLoggedIn: Bool {
        if case .loggedIn = authRepository.authState.value {
            return true
        }
        return false
    }
    
    init(cartRepository: CartRepositoryProtocol, authRepository: AuthRepositoryProtocol) {
        self.cartRepository = cartRepository
        self.authRepository = authRepository
        
        // Observe auth state changes
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case let .loggedIn(user) = state {
                    self?.loadCart(userId: user.id)
                } else {
                    self?.cart = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func loadCart(userId: Int) {
        isLoading = true
        errorMessage = nil
        
        cartRepository.getUserCart(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error loading cart: \(error.localizedDescription)")
                    self?.errorMessage = "Unable to load cart: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] cart in
                Logger.info("Cart loaded successfully with \(cart.items.count) items")
                self?.cart = cart
            }
            .store(in: &cancellables)
    }
    
    func updateItemQuantity(itemId: Int, productId: Int, newQuantity: Int) {
        guard !isUpdatingCart, let userId = getCurrentUserId() else { return }
        
        isUpdatingCart = true
        errorMessage = nil
        
        // First, we need to get the cart
        cartRepository.getUserCart(userId: userId)
            .flatMap { [weak self] cart -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "CartViewModel", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                
                // Then, we update the cart item
                return self.cartRepository.updateItemQuantity(cartId: cart.cartId, itemId: itemId, quantity: newQuantity)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isUpdatingCart = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error updating cart item: \(error.localizedDescription)")
                    self?.errorMessage = "Unable to update item: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] _ in
                Logger.info("Cart item updated successfully")
                self?.successMessage = "Item quantity updated"
                
                // Reload cart
                if let userId = self?.getCurrentUserId() {
                    self?.loadCart(userId: userId)
                }
            }
            .store(in: &cancellables)
    }
    
    func removeItem(itemId: Int, productId: Int) {
        guard !isRemovingItem, let userId = getCurrentUserId() else { return }
        
        isRemovingItem = true
        errorMessage = nil
        
        // First, we need to get the cart
        cartRepository.getUserCart(userId: userId)
            .flatMap { [weak self] cart -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "CartViewModel", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                
                // Según el backend, parece que necesitamos usar productId, no itemId
                return self.cartRepository.removeItem(cartId: cart.cartId, itemId: productId)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isRemovingItem = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error removing cart item: \(error.localizedDescription)")
                    self?.errorMessage = "Unable to remove item: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] _ in
                Logger.info("Cart item removed successfully")
                self?.successMessage = "Item removed from cart"
                
                // Reload cart
                if let userId = self?.getCurrentUserId() {
                    self?.loadCart(userId: userId)
                }
            }
            .store(in: &cancellables)
    }
    
    func clearCart() {
        guard let cart = cart, !isUpdatingCart else { return }
        
        isUpdatingCart = true
        errorMessage = nil
        
        cartRepository.clearCart(cartId: cart.cartId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isUpdatingCart = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error clearing cart: \(error.localizedDescription)")
                    self?.errorMessage = "Unable to clear cart: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] _ in
                Logger.info("Cart cleared successfully")
                self?.successMessage = "Cart cleared"
                
                // Reload cart
                if let userId = self?.getCurrentUserId() {
                    self?.loadCart(userId: userId)
                }
            }
            .store(in: &cancellables)
    }
    
    func proceedToCheckout() {
        guard let cart = cart, !cart.items.isEmpty, !isProcessingCheckout else { return }
        
        isProcessingCheckout = true
        errorMessage = nil
        
        // In a real implementation, this would navigate to checkout flow
        // For now, we'll simulate a successful checkout
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isProcessingCheckout = false
            self?.successMessage = "Redirecting to checkout..."
            
            // Show a success notification
            NotificationService.shared.showSuccess(
                title: "Checkout",
                message: "Proceeding to payment options"
            )
        }
    }
    
    func refreshCart() {
        if let userId = getCurrentUserId() {
            loadCart(userId: userId)
        }
    }
    
    // Helper method to get current user ID
    private func getCurrentUserId() -> Int? {
        if case let .loggedIn(user) = authRepository.authState.value {
            return user.id
        }
        return nil
    }
    
    // Format price for display
    func formattedPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}
