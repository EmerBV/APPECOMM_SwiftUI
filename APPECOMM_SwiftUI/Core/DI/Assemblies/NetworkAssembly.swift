//
//  NetworkAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

final class NetworkAssembly: Assembly {
    func assemble(container: Container) {
        // Base URL Configuration
        container.register(APIConfigurationProtocol.self) { _ in
            APIConfiguration()
        }.inObjectScope(.container)
        
        // Network Logger
        container.register(NetworkLoggerProtocol.self) { _ in
            NetworkLogger()
        }.inObjectScope(.container)
        
        // URLSession Provider
        container.register(URLSessionProviderProtocol.self) { r in
            let configuration = r.resolve(APIConfigurationProtocol.self)!
            let logger = r.resolve(NetworkLoggerProtocol.self)!
            return URLSessionProvider(configuration: configuration, logger: logger)
        }.inObjectScope(.container)
        
        // NetworkDispatcher
        container.register(NetworkDispatcherProtocol.self) { r in
            let sessionProvider = r.resolve(URLSessionProviderProtocol.self)!
            let tokenManager = r.resolve(TokenManagerProtocol.self)!
            return NetworkDispatcher(sessionProvider: sessionProvider, tokenManager: tokenManager)
        }.inObjectScope(.container)
    }
}
