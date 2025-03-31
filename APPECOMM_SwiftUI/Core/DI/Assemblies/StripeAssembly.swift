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
        // Stripe API Client - comunicación directa con API de Stripe
        container.register(StripeAPIClientProtocol.self) { resolver in
            StripeAPIClient(networkDispatcher: resolver.resolve(NetworkDispatcherProtocol.self)!)
        }.inObjectScope(.container)
        
        // Stripe Service - wrapper del SDK de Stripe
        container.register(StripeServiceProtocol.self) { _ in
            StripeService()
        }.inObjectScope(.container)
        
        // Payment Service - lógica de negocio para pagos
        container.register(PaymentServiceProtocol.self) { resolver in
            PaymentService(
                networkDispatcher: resolver.resolve(NetworkDispatcherProtocol.self)!,
                stripeService: resolver.resolve(StripeServiceProtocol.self)!,
                stripeAPIClient: resolver.resolve(StripeAPIClientProtocol.self)!
            )
        }.inObjectScope(.container)
    }
}
