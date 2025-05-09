//
//  UserDefaults+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/5/25.
//

import Foundation

// Extensión para guardar objetos en UserDefaults
extension UserDefaults {
    func save<T: Encodable>(object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            self.set(encoded, forKey: key)
        }
    }
    
    func getObject<T: Decodable>(forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }
}
