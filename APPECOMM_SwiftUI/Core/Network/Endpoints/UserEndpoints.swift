//
//  UserEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

enum UserEndpoints: APIEndpoint {
    case getUserProfile(userId: Int)
    case updateUserProfile(userId: Int, firstName: String, lastName: String)
    
    var path: String {
        switch self {
        case .getUserProfile(let userId):
            return "/users/\(userId)/user"
        case .updateUserProfile(let userId, _, _):
            return "/users/\(userId)/update"
        }
    }
    
    var method: String {
        switch self {
        case .getUserProfile:
            return HTTPMethod.get.rawValue
        case .updateUserProfile:
            return HTTPMethod.put.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .updateUserProfile(_, let firstName, let lastName):
            return ["firstName": firstName, "lastName": lastName]
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
