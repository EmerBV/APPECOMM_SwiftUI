//
//  UserService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol UserServiceProtocol {
    func getUserProfile(userId: Int) -> AnyPublisher<User, NetworkError>
    func updateUserProfile(userId: Int, firstName: String, lastName: String) -> AnyPublisher<User, NetworkError>
}

final class UserService: UserServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getUserProfile(userId: Int) -> AnyPublisher<User, NetworkError> {
        let endpoint = UserEndpoints.getUserProfile(userId: userId)
        return networkDispatcher.dispatch(endpoint)
    }
    
    func updateUserProfile(userId: Int, firstName: String, lastName: String) -> AnyPublisher<User, NetworkError> {
        let endpoint = UserEndpoints.updateUserProfile(
            userId: userId,
            firstName: firstName,
            lastName: lastName
        )
        return networkDispatcher.dispatch(endpoint)
    }
}
