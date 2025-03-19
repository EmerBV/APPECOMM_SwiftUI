//
//  KeychainManager.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Security

protocol KeychainManagerProtocol {
    func save(key: String, data: Data) throws
    func read(key: String) throws -> Data
    func delete(key: String) throws
}

enum KeychainError: Error {
    case duplicateEntry
    case unknown(status: OSStatus)
    case itemNotFound
    case invalidItemFormat
}

final class KeychainManager: KeychainManagerProtocol {
    
    private let service: String
    
    init(service: String = Bundle.main.bundleIdentifier ?? "com.emerbv.APPECOMM-SwiftUI") {
        self.service = service
    }
    
    func save(key: String, data: Data) throws {
        // Crear un query para el item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Primero intentar eliminar cualquier valor existente para esta clave
        SecItemDelete(query as CFDictionary)
        
        // Añadir el nuevo item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Verificar si se pudo añadir correctamente
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateEntry
            }
            throw KeychainError.unknown(status: status)
        }
    }
    
    func read(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status: status)
        }
        
        guard let data = item as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        return data
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status: status)
        }
    }
}
