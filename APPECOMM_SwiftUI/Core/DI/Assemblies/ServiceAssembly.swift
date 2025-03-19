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
    }
}
