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
        
        // WishList ViewModel
        container.register(WishListViewModel.self) { r in
            let wishListRepository = r.resolve(WishListRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return WishListViewModel(wishListRepository: wishListRepository, authRepository: authRepository)
        }.inObjectScope(.container)
        
        
    }
}
