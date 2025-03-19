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
}

final class AuthService: AuthServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func login(email: String, password: String) -> AnyPublisher<AuthToken, NetworkError> {
        let endpoint = AuthEndpoints.login(email: email, password: password)
        print("AuthService: Calling login endpoint")
        
        return networkDispatcher.dispatch(ApiResponse<AuthToken>.self, endpoint)
            .map { response -> AuthToken in
                print("AuthService: Login successful with message: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("AuthService: Login failed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, NetworkError> {
        let endpoint = AuthEndpoints.logout
        print("AuthService: Calling logout endpoint")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                print("AuthService: Logout successful")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("AuthService: Logout failed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}

// Estructura vacía para respuestas que no tienen datos
struct EmptyResponse: Codable {}
