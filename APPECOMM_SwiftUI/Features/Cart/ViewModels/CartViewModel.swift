//
//  CartViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 21/3/25.
//

import Foundation
import Combine
import SwiftUI

final class CartViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var cart: Cart?
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdatingCart = false
    @Published private(set) var isRemovingItem = false
    @Published private(set) var isProcessingCheckout = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Dependencies
    private let cartRepository: CartRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private let navigationCoordinator: NavigationCoordinatorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Indicates if the user is currently logged in
    var isUserLoggedIn: Bool {
        if case .loggedIn = authRepository.authState.value {
            return true
        }
        return false
    }
    
    /// Returns the formatted total price of the cart
    var formattedTotalPrice: String? {
        cart?.totalAmount.toCurrentLocalePrice
    }
    
    /// Returns the number of items in the cart
    var itemCount: Int {
        cart?.items.count ?? 0
    }
    
    /// Returns true if the cart is empty
    var isCartEmpty: Bool {
        cart?.items.isEmpty ?? true
    }
    
    // MARK: - Initialization
    
    init(
        cartRepository: CartRepositoryProtocol,
        authRepository: AuthRepositoryProtocol,
        navigationCoordinator: NavigationCoordinatorProtocol = NavigationCoordinator.shared
    ) {
        self.cartRepository = cartRepository
        self.authRepository = authRepository
        self.navigationCoordinator = navigationCoordinator
        
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    
    /// Sets up subscriptions to observe auth state changes
    private func setupSubscriptions() {
        // Observe auth state changes to automatically load cart when user logs in
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
    
    /// Returns the current user ID if available
    private func getCurrentUserId() -> Int? {
        if case let .loggedIn(user) = authRepository.authState.value {
            return user.id
        }
        return nil
    }
    
    /// Shows a notification toast with error message
    private func showErrorNotification(title: String = "error".localized, message: String) {
        NotificationService.shared.showError(title: title, message: message)
        errorMessage = message
    }
    
    /// Shows a notification toast with success message
    private func showSuccessNotification(title: String = "success".localized, message: String) {
        NotificationService.shared.showSuccess(title: title, message: message)
        successMessage = message
        
        // Auto-hide success message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.successMessage = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the user's cart
    /// - Parameter userId: The ID of the user whose cart to load
    func loadCart(userId: Int) {
        isLoading = true
        errorMessage = nil
        
        Logger.info("Loading cart for user \(userId)")
        
        cartRepository.getUserCart(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Failed to load cart: \(error.localizedDescription)")
                    self?.errorMessage = String(format: "unable_to_load_cart".localized, error.localizedDescription)
                }
            } receiveValue: { [weak self] cart in
                Logger.info("Cart loaded successfully with \(cart.items.count) items")
                self?.cart = cart
            }
            .store(in: &cancellables)
    }
    
    /// Refreshes the cart data asynchronously
    @MainActor
    func refreshCart() async {
        guard let userId = getCurrentUserId() else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let publisher = cartRepository.getUserCart(userId: userId)
            
            for try await cart in publisher.values {
                self.cart = cart
                Logger.info("Cart refreshed successfully with \(cart.items.count) items")
                break
            }
        } catch {
            Logger.error("Error refreshing cart: \(error.localizedDescription)")
            errorMessage = String(format: "unable_to_load_cart".localized, error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Updates the quantity of an item in the cart
    /// - Parameters:
    ///   - itemId: The ID of the item
    ///   - productId: The ID of the product
    ///   - newQuantity: The new quantity
    @MainActor
    func updateItemQuantity(itemId: Int, productId: Int, newQuantity: Int) async {
        guard !isUpdatingCart, let userId = getCurrentUserId(), let cartId = cart?.cartId else {
            return
        }
        
        isUpdatingCart = true
        errorMessage = nil
        
        Logger.info("Updating quantity for item \(itemId) to \(newQuantity)")
        
        do {
            let updatePublisher = cartRepository.updateItemQuantity(
                cartId: cartId,
                itemId: productId,
                quantity: newQuantity
            )
            
            for try await _ in updatePublisher.values {
                // Update successful, reload cart to get updated state
                let cartPublisher = cartRepository.getUserCart(userId: userId)
                
                for try await updatedCart in cartPublisher.values {
                    self.cart = updatedCart
                    showSuccessNotification(message: "item_quantity_updated".localized)
                    Logger.info("Item quantity updated successfully")
                    break
                }
                break
            }
        } catch {
            Logger.error("Failed to update item quantity: \(error.localizedDescription)")
            showErrorNotification(message: String(format: "unable_to_update_item".localized, error.localizedDescription))
        }
        
        isUpdatingCart = false
    }
    
    /// Removes an item from the cart
    /// - Parameters:
    ///   - itemId: The ID of the item
    ///   - productId: The ID of the product
    @MainActor
    func removeItem(itemId: Int, productId: Int) async {
        guard !isRemovingItem, let userId = getCurrentUserId(), let cartId = cart?.cartId else {
            return
        }
        
        isRemovingItem = true
        errorMessage = nil
        
        Logger.info("Removing item \(itemId) from cart")
        
        do {
            let removePublisher = cartRepository.removeItem(cartId: cartId, itemId: productId)
            
            for try await _ in removePublisher.values {
                // Item removed, reload cart to get updated state
                let cartPublisher = cartRepository.getUserCart(userId: userId)
                
                for try await updatedCart in cartPublisher.values {
                    self.cart = updatedCart
                    showSuccessNotification(message: "item_removed".localized)
                    Logger.info("Item removed successfully")
                    break
                }
                break
            }
        } catch {
            Logger.error("Failed to remove item: \(error.localizedDescription)")
            showErrorNotification(message: String(format: "unable_to_remove_item".localized, error.localizedDescription))
        }
        
        isRemovingItem = false
    }
    
    /// Clears all items from the cart
    @MainActor
    func clearCart() async {
        guard let userId = getCurrentUserId(), let cartId = cart?.cartId, !isUpdatingCart else {
            return
        }
        
        isUpdatingCart = true
        errorMessage = nil
        
        Logger.info("Clearing cart \(cartId)")
        
        do {
            let clearPublisher = cartRepository.clearCart(cartId: cartId)
            
            for try await _ in clearPublisher.values {
                // Cart cleared, reload to get updated state
                let cartPublisher = cartRepository.getUserCart(userId: userId)
                
                for try await updatedCart in cartPublisher.values {
                    self.cart = updatedCart
                    showSuccessNotification(message: "cart_cleared".localized)
                    Logger.info("Cart cleared successfully")
                    break
                }
                break
            }
        } catch {
            Logger.error("Failed to clear cart: \(error.localizedDescription)")
            showErrorNotification(message: String(format: "unable_to_clear_cart".localized, error.localizedDescription))
        }
        
        isUpdatingCart = false
    }
    
    /// Handles the checkout process
    @MainActor
    func proceedToCheckout() async {
        guard let cart = cart, !cart.items.isEmpty, !isProcessingCheckout else {
            return
        }
        
        // Check if user is logged in first
        guard isUserLoggedIn else {
            showErrorNotification(title: "Login Required", message: "Please log in to proceed with checkout")
            navigationCoordinator.navigateToLogin()
            return
        }
        
        isProcessingCheckout = true
        errorMessage = nil
        
        Logger.info("Proceeding to checkout with \(cart.items.count) items")
        
        // Navigate to checkout screen using the coordinator
        navigationCoordinator.navigateToCheckout(with: cart)
        
        isProcessingCheckout = false
    }
    
    /// Returns the formatted price for a cart item
    /// - Parameter item: The cart item
    /// - Returns: Formatted price string
    func formattedPrice(for item: CartItem) -> String {
        return item.totalPrice.toCurrentLocalePrice
    }
    
    /// Returns the formatted unit price for a cart item
    /// - Parameter item: The cart item
    /// - Returns: Formatted unit price string
    func formattedUnitPrice(for item: CartItem) -> String {
        return item.unitPrice.toCurrentLocalePrice
    }
    
    /// Dismisses the current error message
    func dismissError() {
        errorMessage = nil
    }
}
