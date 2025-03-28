//
//  NavigationCoordinator.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI
import Combine

// Protocol defined for NavigationCoordinator used by CartViewModel
protocol NavigationCoordinatorProtocol {
    func navigateToCheckout(with cart: Cart)
    func navigateToProductList()
    func navigateToLogin()
    func dismissCurrentView()
}

class NavigationCoordinator: ObservableObject, NavigationCoordinatorProtocol {
    // Published properties for view state
    @Published var showingCheckout = false
    @Published var navigatingToProductList = false
    @Published var navigatingToLogin = false
    @Published var currentCart: Cart?
    @Published var shouldDismissCurrent = false
    
    // Singleton instance
    static let shared = NavigationCoordinator()
    
    // Dependencies
    private let cartRepository: CartRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Using dependency injection for repositories
        let dependencies = DependencyInjector.shared
        self.cartRepository = dependencies.resolve(CartRepositoryProtocol.self)
        self.authRepository = dependencies.resolve(AuthRepositoryProtocol.self)
        
        setupSubscriptions()
    }
    
    // Setup necessary subscriptions
    private func setupSubscriptions() {
        // Listen for authentication changes
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .loggedOut = state {
                    // Reset state when user logs out
                    self?.showingCheckout = false
                    self?.currentCart = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to checkout with the given cart
    func navigateToCheckout(with cart: Cart) {
        Logger.info("Navigating to checkout with cart ID: \(cart.cartId)")
        self.currentCart = cart
        self.showingCheckout = true
    }
    
    /// Navigate to product list
    func navigateToProductList() {
        Logger.info("Navigating to product list")
        self.navigatingToProductList = true
        
        // Reset after navigation is handled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigatingToProductList = false
        }
    }
    
    /// Navigate to login screen
    func navigateToLogin() {
        Logger.info("Navigating to login")
        self.navigatingToLogin = true
        
        // Reset after navigation is handled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigatingToLogin = false
        }
    }
    
    /// Dismiss current view
    func dismissCurrentView() {
        Logger.info("Dismissing current view")
        self.shouldDismissCurrent = true
        
        // Reset after navigation is handled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldDismissCurrent = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset all navigation states
    func resetNavigationState() {
        self.showingCheckout = false
        self.navigatingToProductList = false
        self.navigatingToLogin = false
        self.shouldDismissCurrent = false
        self.currentCart = nil
    }
}
