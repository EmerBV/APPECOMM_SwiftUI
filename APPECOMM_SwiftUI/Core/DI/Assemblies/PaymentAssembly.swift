//
//  PaymentAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 25/4/25.
//

import Foundation
import Swinject

/// Assembly for payment-related dependencies
final class PaymentAssembly: Assembly {
    func assemble(container: Container) {
        // Register Stripe API Client
        container.register(StripeAPIClientProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return StripeAPIClient(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Register Stripe Service
        container.register(StripeServiceProtocol.self) { _ in
            StripeService()
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
        
        // Register Payment ViewModel
        container.register(PaymentViewModel.self) { r in
            let paymentService = r.resolve(PaymentServiceProtocol.self)!
            let stripeService = r.resolve(StripeServiceProtocol.self)!
            let stripeAPIClient = r.resolve(StripeAPIClientProtocol.self)!
            
            return PaymentViewModel(
                paymentService: paymentService,
                stripeService: stripeService,
                stripeAPIClient: stripeAPIClient
            )
        }
    }
}
