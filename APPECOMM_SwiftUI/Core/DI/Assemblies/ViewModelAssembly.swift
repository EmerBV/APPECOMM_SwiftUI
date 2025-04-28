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
