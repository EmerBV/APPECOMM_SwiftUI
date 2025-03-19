//
//  AuthEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

enum AuthEndpoints: APIEndpoint {
    case login(email: String, password: String)
    case logout
    case refreshToken(refreshToken: String)
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        }
    }
    
    var method: String {
        switch self {
        case .login, .refreshToken:
            return HTTPMethod.post.rawValue
        case .logout:
            return HTTPMethod.delete.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .refreshToken(let refreshToken):
            return ["refreshToken": refreshToken]
        case .logout:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .login, .refreshToken:
            return false
        case .logout:
            return true
        }
    }
    
    var isRefreshTokenEndpoint: Bool {
        switch self {
        case .refreshToken:
            return true
        default:
            return false
        }
    }
}
