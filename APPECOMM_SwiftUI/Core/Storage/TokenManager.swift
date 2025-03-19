//
//  TokenManager.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

protocol TokenManagerProtocol {
    func saveTokens(accessToken: String, refreshToken: String?, userId: Int) throws
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func getUserId() -> Int?
    func clearTokens() throws
    func hasValidToken() -> Bool
}

final class TokenManager: TokenManagerProtocol {
    private enum TokenKeys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
    }
    
    private let secureStorage: SecureStorageProtocol
    
    init(secureStorage: SecureStorageProtocol) {
        self.secureStorage = secureStorage
    }
    
    func saveTokens(accessToken: String, refreshToken: String?, userId: Int) throws {
        try secureStorage.saveString(accessToken, forKey: TokenKeys.accessToken)
        
        if let refreshToken = refreshToken {
            try secureStorage.saveString(refreshToken, forKey: TokenKeys.refreshToken)
        }
        
        try secureStorage.saveObject(userId, forKey: TokenKeys.userId)
    }
    
    func getAccessToken() -> String? {
        do {
            return try secureStorage.getString(forKey: TokenKeys.accessToken)
        } catch {
            return nil
        }
    }
    
    func getRefreshToken() -> String? {
        do {
            return try secureStorage.getString(forKey: TokenKeys.refreshToken)
        } catch {
            return nil
        }
    }
    
    func getUserId() -> Int? {
        do {
            return try secureStorage.getObject(forKey: TokenKeys.userId)
        } catch {
            return nil
        }
    }
    
    func clearTokens() throws {
        try secureStorage.removeObject(forKey: TokenKeys.accessToken)
        try secureStorage.removeObject(forKey: TokenKeys.refreshToken)
        try secureStorage.removeObject(forKey: TokenKeys.userId)
    }
    
    func hasValidToken() -> Bool {
        return getAccessToken() != nil
    }
}
