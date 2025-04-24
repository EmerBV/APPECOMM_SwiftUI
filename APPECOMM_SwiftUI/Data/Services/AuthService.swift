//
//  AuthService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<AuthToken, NetworkError>
    func logout() -> AnyPublisher<Void, NetworkError>
    func register(firstName: String, lastName: String, email: String, password: String) -> AnyPublisher<User, NetworkError>
}

final class AuthService: AuthServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func login(email: String, password: String) -> AnyPublisher<AuthToken, NetworkError> {
        let endpoint = AuthEndpoints.login(email: email, password: password)
        Logger.debug("AuthService: Calling login endpoint")
        
        return networkDispatcher.dispatch(ApiResponse<AuthToken>.self, endpoint)
            .map { response -> AuthToken in
                Logger.info("AuthService: Login successful with message: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("AuthService: Login failed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, NetworkError> {
        let endpoint = AuthEndpoints.logout
        Logger.debug("AuthService: Calling logout endpoint")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("AuthService: Logout successful")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("AuthService: Logout failed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func register(firstName: String, lastName: String, email: String, password: String) -> AnyPublisher<User, NetworkError> {
        let endpoint = AuthEndpoints.register(firstName: firstName, lastName: lastName, email: email, password: password)
        Logger.debug("AuthService: Calling register endpoint")
        
        return networkDispatcher.dispatch(ApiResponse<User>.self, endpoint)
            .map { response -> User in
                Logger.info("AuthService: Registration successful with message: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("AuthService: Registration failed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}

// Estructura vacía para respuestas que no tienen datos
struct EmptyResponse: Codable {}
