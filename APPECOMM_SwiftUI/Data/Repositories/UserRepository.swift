//
//  UserRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol UserRepositoryProtocol {
    func getUserProfile(userId: Int) -> AnyPublisher<User, Error>
    func updateUserProfile(userId: Int, firstName: String, lastName: String) -> AnyPublisher<User, Error>
    func getCurrentUser() -> User?
}

final class UserRepository: UserRepositoryProtocol {
    private static let userKey = "current_user"
    
    private let userService: UserServiceProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    init(userService: UserServiceProtocol, userDefaultsManager: UserDefaultsManagerProtocol) {
        self.userService = userService
        self.userDefaultsManager = userDefaultsManager
    }
    
    func getUserProfile(userId: Int) -> AnyPublisher<User, Error> {
        return userService.getUserProfile(userId: userId)
            .handleEvents(receiveOutput: { [weak self] user in
                // Actualizar el usuario en local
                self?.userDefaultsManager.save(object: user, forKey: Self.userKey)
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateUserProfile(userId: Int, firstName: String, lastName: String) -> AnyPublisher<User, Error> {
        return userService.updateUserProfile(userId: userId, firstName: firstName, lastName: lastName)
            .handleEvents(receiveOutput: { [weak self] user in
                // Actualizar el usuario en local
                self?.userDefaultsManager.save(object: user, forKey: Self.userKey)
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User? {
        return userDefaultsManager.get(objectType: User.self, forKey: Self.userKey)
    }
}
