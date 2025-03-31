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
        
        // Register Payment Service
        container.register(PaymentServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            let stripeService = r.resolve(StripeServiceProtocol.self)!
            let stripeAPIClient = r.resolve(StripeAPIClientProtocol.self)!
            return PaymentService(
                networkDispatcher: networkDispatcher,
                stripeService: stripeService,
                stripeAPIClient: stripeAPIClient
            )
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
    }
}
