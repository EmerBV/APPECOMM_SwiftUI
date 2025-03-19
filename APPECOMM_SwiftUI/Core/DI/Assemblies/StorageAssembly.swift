//
//  StorageAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

final class StorageAssembly: Assembly {
    func assemble(container: Container) {
        // Keychain Manager
        container.register(KeychainManagerProtocol.self) { _ in
            KeychainManager()
        }.inObjectScope(.container)
        
        // Secure Storage
        container.register(SecureStorageProtocol.self) { r in
            let keychainManager = r.resolve(KeychainManagerProtocol.self)!
            return SecureStorage(keychainManager: keychainManager)
        }.inObjectScope(.container)
        
        // User Defaults Manager
        container.register(UserDefaultsManagerProtocol.self) { _ in
            UserDefaultsManager()
        }.inObjectScope(.container)
        
        // Token Manager
        container.register(TokenManagerProtocol.self) { r in
            let secureStorage = r.resolve(SecureStorageProtocol.self)!
            return TokenManager(secureStorage: secureStorage)
        }.inObjectScope(.container)
    }
}
