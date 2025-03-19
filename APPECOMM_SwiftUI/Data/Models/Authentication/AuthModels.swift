//
//  AuthModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

struct AuthToken: Codable, Equatable {
    let id: Int
    let token: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let message: String
    let data: AuthToken
}
