//
//  TokenManager+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

// Extensión para acceder al TokenManager compartido
extension TokenManager {
    static var shared: TokenManagerProtocol {
        // Esta es una implementación sencilla para acceder al TokenManager
        // En una app real, deberías configurar esto mediante inyección de dependencias
        let secureStorage = SecureStorage(keychainManager: KeychainManager())
        return TokenManager(secureStorage: secureStorage)
    }
}
