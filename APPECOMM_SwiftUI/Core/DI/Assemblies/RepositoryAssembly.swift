//
//  RepositoryAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

final class RepositoryAssembly: Assembly {
    func assemble(container: Container) {
        // Auth Repository
        container.register(AuthRepositoryProtocol.self) { r in
            let authService = r.resolve(AuthServiceProtocol.self)!
            let tokenManager = r.resolve(TokenManagerProtocol.self)!
            let userDefaultsManager = r.resolve(UserDefaultsManagerProtocol.self)!
            let userService = r.resolve(UserServiceProtocol.self)!
            
            return AuthRepository(
                authService: authService,
                tokenManager: tokenManager,
                userDefaultsManager: userDefaultsManager,
                userService: userService
            )
        }.inObjectScope(.container)
        
        // User Repository
        container.register(UserRepositoryProtocol.self) { r in
            let userService = r.resolve(UserServiceProtocol.self)!
            let userDefaultsManager = r.resolve(UserDefaultsManagerProtocol.self)!
            return UserRepository(
                userService: userService,
                userDefaultsManager: userDefaultsManager
            )
        }.inObjectScope(.container)
        
        // Product Repository
        container.register(ProductRepositoryProtocol.self) { r in
            let productService = r.resolve(ProductServiceProtocol.self)!
            return ProductRepository(productService: productService)
        }.inObjectScope(.container)
        
        // Cart Repository
        container.register(CartRepositoryProtocol.self) { r in
            let cartService = r.resolve(CartServiceProtocol.self)!
            return CartRepository(cartService: cartService)
        }.inObjectScope(.container)
        
        // Checkout Repository (with consolidated order management)
        container.register(CheckoutRepositoryProtocol.self) { r in
            let checkoutService = r.resolve(CheckoutServiceProtocol.self)!
            let paymentService = r.resolve(PaymentServiceProtocol.self)!
            return CheckoutRepository(
                checkoutService: checkoutService,
                paymentService: paymentService
            )
        }.inObjectScope(.container)
        
        // Shipping Repository
        container.register(ShippingRepositoryProtocol.self) { r in
            let shippingService = r.resolve(ShippingServiceProtocol.self)!
            return ShippingRepository(shippingService: shippingService)
        }.inObjectScope(.container)
    }
}
