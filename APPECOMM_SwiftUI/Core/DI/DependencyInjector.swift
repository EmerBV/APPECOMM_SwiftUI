//
//  DependencyInjector.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject


/// Central dependency injection manager
final class DependencyInjector {
    static let shared = DependencyInjector()
    
    private let container: Container
    private let assembler: Assembler
    
    private init() {
        container = Container()
        
        // Register all assemblies
        assembler = Assembler(
            [
                NetworkAssembly(),
                StorageAssembly(),
                ServiceAssembly(),
                RepositoryAssembly(),
                ViewModelAssembly(),
                CheckoutAssembly(),
                StripeAssembly()
            ],
            container: container
        )
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolvedType = container.resolve(T.self) else {
            fatalError("Could not resolve type \(String(describing: T.self))")
        }
        return resolvedType
    }
}

extension DependencyInjector {
    func registerServices() {
        container.register(StripeServiceProtocol.self) { _ in
            StripeService()
        }
        
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
