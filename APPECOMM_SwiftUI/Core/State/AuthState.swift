//
//  AuthState.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

enum AuthState: Equatable {
    case loggedIn(User)
    case loggedOut
    case loading
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loggedIn(let lhsUser), .loggedIn(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.loggedOut, .loggedOut):
            return true
        case (.loading, .loading):
            return true
        default:
            return false
        }
    }
}
