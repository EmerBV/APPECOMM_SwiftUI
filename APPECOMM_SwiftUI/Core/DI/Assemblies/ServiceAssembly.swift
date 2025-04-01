//
//  ServiceAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

final class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        // Auth Service
        container.register(AuthServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return AuthService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // User Service
        container.register(UserServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return UserService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Product Service
        container.register(ProductServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return ProductService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Cart Service
        container.register(CartServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return CartService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Payment Service
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
        
        // Shipping Service
        container.register(ShippingServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return ShippingService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Order Service
        container.register(OrderServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return OrderService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
    }
}
