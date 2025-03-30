//
//  StripeAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Swinject

class StripeAssembly: Assembly {
    func assemble(container: Container) {
        // Stripe Service
        container.register(StripeServiceProtocol.self) { _ in
            StripeService()
        }.inObjectScope(.container)
        
        // Stripe API Client
        container.register(StripeAPIClientProtocol.self) { resolver in
            StripeAPIClient(networkDispatcher: resolver.resolve(NetworkDispatcherProtocol.self)!)
        }.inObjectScope(.container)
        
        // Payment Service
        container.register(PaymentServiceProtocol.self) { resolver in
            PaymentService(
                networkDispatcher: resolver.resolve(NetworkDispatcherProtocol.self)!,
                stripeService: resolver.resolve(StripeServiceProtocol.self)!,
                stripeAPIClient: resolver.resolve(StripeAPIClientProtocol.self)!
            )
        }.inObjectScope(.container)
    }
}
