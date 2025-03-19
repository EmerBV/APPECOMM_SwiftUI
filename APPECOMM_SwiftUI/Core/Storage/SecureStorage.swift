//
//  SecureStorage.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

protocol SecureStorageProtocol {
    func saveObject<T: Encodable>(_ object: T, forKey key: String) throws
    func getObject<T: Decodable>(forKey key: String) throws -> T
    func removeObject(forKey key: String) throws
    
    func saveString(_ string: String, forKey key: String) throws
    func getString(forKey key: String) throws -> String
}

final class SecureStorage: SecureStorageProtocol {
    private let keychainManager: KeychainManagerProtocol
    
    init(keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
    }
    
    func saveObject<T: Encodable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try keychainManager.save(key: key, data: data)
    }
    
    func getObject<T: Decodable>(forKey key: String) throws -> T {
        let data = try keychainManager.read(key: key)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func removeObject(forKey key: String) throws {
        try keychainManager.delete(key: key)
    }
    
    func saveString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        try keychainManager.save(key: key, data: data)
    }
    
    func getString(forKey key: String) throws -> String {
        let data = try keychainManager.read(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        return string
    }
}
