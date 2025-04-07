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
        Logger.debug("UserService: Fetching user profile for userId: \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<User>.self, endpoint)
            .map { response -> User in
                Logger.info("UserService: Successfully retrieved user profile")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("UserService: Failed to get user profile: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func updateUserProfile(userId: Int, firstName: String, lastName: String) -> AnyPublisher<User, NetworkError> {
        let endpoint = UserEndpoints.updateUserProfile(userId: userId, firstName: firstName, lastName: lastName)
        Logger.debug("UserService: Updating user profile for userId: \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<User>.self, endpoint)
            .map { response -> User in
                Logger.info("UserService: Successfully updated user profile")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("UserService: Failed to update user profile: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}

