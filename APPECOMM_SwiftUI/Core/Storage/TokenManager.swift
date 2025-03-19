//
//  TokenManager.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import JWTDecode

protocol TokenManagerProtocol {
    func saveTokens(accessToken: String, refreshToken: String?, userId: Int) throws
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func getUserId() -> Int?
    func clearTokens() throws
    func hasValidToken() -> Bool
    func getTokenExpiration() -> Date?
}

final class TokenManager: TokenManagerProtocol {
    private enum TokenKeys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let tokenExpiration = "token_expiration"
    }
    
    private let secureStorage: SecureStorageProtocol
    
    private var tokenExpirationCache: [String: Date] = [:]
    
    init(secureStorage: SecureStorageProtocol) {
        self.secureStorage = secureStorage
    }
    
    func saveTokens(accessToken: String, refreshToken: String?, userId: Int) throws {
        try secureStorage.saveString(accessToken, forKey: TokenKeys.accessToken)
        
        if let refreshToken = refreshToken {
            try secureStorage.saveString(refreshToken, forKey: TokenKeys.refreshToken)
        }
        
        try secureStorage.saveObject(userId, forKey: TokenKeys.userId)
        
        // Extraer fecha de expiración del token JWT si es posible
        if let expirationDate = extractTokenExpiration(from: accessToken) {
            try secureStorage.saveObject(expirationDate, forKey: TokenKeys.tokenExpiration)
            Logger.debug("Token expira el: \(expirationDate)")
        }
    }
    
    func getAccessToken() -> String? {
        do {
            return try secureStorage.getString(forKey: TokenKeys.accessToken)
        } catch {
            Logger.error("Error al obtener access token: \(error)")
            return nil
        }
    }
    
    func getRefreshToken() -> String? {
        do {
            return try secureStorage.getString(forKey: TokenKeys.refreshToken)
        } catch {
            Logger.error("Error al obtener refresh token: \(error)")
            return nil
        }
    }
    
    func getUserId() -> Int? {
        do {
            return try secureStorage.getObject(forKey: TokenKeys.userId)
        } catch {
            Logger.error("Error al obtener user ID: \(error)")
            return nil
        }
    }
    
    func clearTokens() throws {
        try secureStorage.removeObject(forKey: TokenKeys.accessToken)
        try secureStorage.removeObject(forKey: TokenKeys.refreshToken)
        try secureStorage.removeObject(forKey: TokenKeys.userId)
        try secureStorage.removeObject(forKey: TokenKeys.tokenExpiration)
    }
    
    func hasValidToken() -> Bool {
        guard let _ = getAccessToken() else {
            return false
        }
        
        // Verificar si el token ha expirado
        if let expirationDate = getTokenExpiration() {
            let currentDate = Date()
            
            // Considerar el token no válido 1 minuto antes de que expire
            let expirationWithBuffer = expirationDate.addingTimeInterval(-60)
            
            if currentDate > expirationWithBuffer {
                Logger.warning("Token expirado o próximo a expirar")
                return false
            }
        }
        
        return true
    }
    
    func getTokenExpiration() -> Date? {
        do {
            // Primero intentar obtener la fecha almacenada
            return try secureStorage.getObject(forKey: TokenKeys.tokenExpiration)
        } catch {
            // Si no hay fecha almacenada, intentar extraerla del token
            if let token = getAccessToken() {
                return extractTokenExpiration(from: token)
            }
            return nil
        }
    }
    
    private func extractTokenExpiration(from token: String) -> Date? {
        
        // Verificar cache primero
        /*
        if let cachedDate = tokenExpirationCache[token] {
            return cachedDate
        }
         */
        
        // Dividir el token en sus 3 partes: header.payload.signature
        let parts = token.components(separatedBy: ".")
        
        guard parts.count == 3 else {
            Logger.error("El token no tiene el formato JWT esperado")
            return nil
        }
        
        // Decodificar el payload (segunda parte)
        guard let payload = parts[1].base64UrlDecoded() else {
            Logger.error("No se pudo decodificar el payload del token")
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                // exp está en segundos desde epoch (1970-01-01)
                return Date(timeIntervalSince1970: exp)
            }
        } catch {
            Logger.error("Error al parsear JSON del token: \(error)")
        }
        
        // Si se encontró una fecha, guardarla en caché
        /*
        if let expirationDate = /* fecha decodificada */ {
            tokenExpirationCache[token] = expirationDate
            return expirationDate
        }
         */
        
        return nil
    }
}

// Extensión para decodificar base64url
extension String {
    func base64UrlDecoded() -> Data? {
        // Ajustar el padding para base64
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        return Data(base64Encoded: base64)
    }
}

// Añadir este import al principio del archivo
// En un proyecto real, JWT sería una dependencia externa vía SPM o CocoaPods
// Para simplificar, aquí creamos una implementación básica
enum JWT {
    static func decode(_ token: String) -> [String: Any]? {
        let parts = token.components(separatedBy: ".")
        
        guard parts.count == 3 else {
            return nil
        }
        
        guard let payloadData = parts[1].base64UrlDecoded() else {
            return nil
        }
        
        do {
            return try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any]
        } catch {
            return nil
        }
    }
}
