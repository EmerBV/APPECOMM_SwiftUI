//
//  ViewModelAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

final class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        // Input Validator
        container.register(InputValidatorProtocol.self) { _ in
            InputValidator()
        }.inObjectScope(.container)
        
        // Auth ViewModel
        container.register(AuthViewModel.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let validator = r.resolve(InputValidatorProtocol.self)!
            return AuthViewModel(authRepository: authRepository, validator: validator)
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Product List ViewModel
        container.register(ProductListViewModel.self) { r in
            let productRepository = r.resolve(ProductRepositoryProtocol.self)!
            let cartRepository = r.resolve(CartRepositoryProtocol.self)!
            return ProductListViewModel(
                productRepository: productRepository,
                cartRepository: cartRepository
            )
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Cart ViewModel
        container.register(CartViewModel.self) { r in
            let cartRepository = r.resolve(CartRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return CartViewModel(
                cartRepository: cartRepository,
                authRepository: authRepository
            )
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Home ViewModel
        container.register(HomeViewModel.self) { r in
            let productRepository = r.resolve(ProductRepositoryProtocol.self)!
            return HomeViewModel(productRepository: productRepository)
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Profile ViewModel
        container.register(ProfileViewModel.self) { r in
            let userRepository = r.resolve(UserRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return ProfileViewModel(
                userRepository: userRepository,
                authRepository: authRepository
            )
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Orders ViewModel
        container.register(OrdersViewModel.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let paymentService = r.resolve(PaymentServiceProtocol.self)!
            return OrdersViewModel(
                authRepository: authRepository,
                paymentService: paymentService
            )
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Shipping Addresses ViewModel
        container.register(ShippingAddressesViewModel.self) { r in
            let shippingRepository = r.resolve(ShippingRepositoryProtocol.self)!
            return ShippingAddressesViewModel(shippingRepository: shippingRepository)
        }.inObjectScope(.container)
        
        // Checkout ViewModel
        container.register(CheckoutViewModel.self) { resolver in
            let cart = resolver.resolve(Cart.self)
            let checkoutService = resolver.resolve(CheckoutServiceProtocol.self)!
            let paymentService = resolver.resolve(PaymentServiceProtocol.self)!
            let authRepository = resolver.resolve(AuthRepositoryProtocol.self)!
            let validator = resolver.resolve(InputValidatorProtocol.self)!
            let shippingService = resolver.resolve(ShippingServiceProtocol.self)!
            let stripeService = resolver.resolve(StripeServiceProtocol.self)!
            
            return CheckoutViewModel(
                cart: cart,
                checkoutService: checkoutService,
                paymentService: paymentService,
                authRepository: authRepository,
                validator: validator,
                shippingService: shippingService,
                stripeService: stripeService
            )
        }
    }
}
