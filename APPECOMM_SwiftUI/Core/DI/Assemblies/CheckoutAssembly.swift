//
//  CheckoutAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Swinject

/// Assembly for checkout-related dependencies
final class CheckoutAssembly: Assembly {
    func assemble(container: Container) {
        // Register Checkout Service
        container.register(CheckoutServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return CheckoutService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Register Checkout Repository
        container.register(CheckoutRepositoryProtocol.self) { r in
            let checkoutService = r.resolve(CheckoutServiceProtocol.self)!
            let paymentService = r.resolve(PaymentServiceProtocol.self)!
            return CheckoutRepository(
                checkoutService: checkoutService,
                paymentService: paymentService
            )
        }.inObjectScope(.container)
        
        // Register Input Validator
        container.register(InputValidatorProtocol.self) { _ in
            InputValidator()
        }.inObjectScope(.container)
        
        // Register Checkout ViewModel
        container.register(CheckoutViewModel.self) { (r, cart: Cart?) in
            let checkoutService = r.resolve(CheckoutServiceProtocol.self)!
            let paymentService = r.resolve(PaymentServiceProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let validator = r.resolve(InputValidatorProtocol.self)!
            let shippingService = r.resolve(ShippingServiceProtocol.self)!
            let stripeService = r.resolve(StripeServiceProtocol.self)!
            let shippingRepository = r.resolve(ShippingRepositoryProtocol.self)!
            
            return CheckoutViewModel(
                cart: cart,
                checkoutService: checkoutService,
                paymentService: paymentService,
                authRepository: authRepository,
                validator: validator,
                shippingService: shippingService,
                stripeService: stripeService,
                shippingRepository: shippingRepository
            )
        }
        
        // Register PaymentSheetViewModel
        container.register(PaymentSheetViewModel.self) { (r, orderId: Int, amount: Decimal, email: String?) in
            let paymentService = r.resolve(PaymentServiceProtocol.self)!
            let navigationCoordinator = NavigationCoordinator.shared
            
            return PaymentSheetViewModel(
                paymentService: paymentService,
                orderId: orderId,
                amount: amount,
                email: email,
                navigationCoordinator: navigationCoordinator
            )
        }
    }
}
