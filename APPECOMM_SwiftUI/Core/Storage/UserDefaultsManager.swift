//
//  UserDefaultsManager.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

protocol UserDefaultsManagerProtocol {
    func save<T: Encodable>(object: T, forKey key: String)
    func get<T: Decodable>(objectType: T.Type, forKey key: String) -> T?
    func save(value: Any?, forKey key: String)
    func getString(forKey key: String) -> String?
    func getInt(forKey key: String) -> Int?
    func getBool(forKey key: String) -> Bool?
    func getDate(forKey key: String) -> Date?
    func remove(forKey key: String)
    func clearAll()
}

final class UserDefaultsManager: UserDefaultsManagerProtocol {
    private let defaults = UserDefaults.standard
    
    func save<T: Encodable>(object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func get<T: Decodable>(objectType: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }
    
    func save(value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }
    
    func getInt(forKey key: String) -> Int? {
        return defaults.object(forKey: key) as? Int
    }
    
    func getBool(forKey key: String) -> Bool? {
        return defaults.object(forKey: key) as? Bool
    }
    
    func getDate(forKey key: String) -> Date? {
        return defaults.object(forKey: key) as? Date
    }
    
    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    func clearAll() {
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            // Evitar borrar configuraciones del sistema
            if !key.starts(with: "com.apple") {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
