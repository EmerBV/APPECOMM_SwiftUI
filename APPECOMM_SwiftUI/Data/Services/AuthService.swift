//
//  AuthService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, NetworkError>
    func logout() -> AnyPublisher<Void, NetworkError>
}

final class AuthService: AuthServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, NetworkError> {
        let endpoint = AuthEndpoints.login(email: email, password: password)
        return networkDispatcher.dispatch(endpoint)
    }
    
    func logout() -> AnyPublisher<Void, NetworkError> {
        let endpoint = AuthEndpoints.logout
        return networkDispatcher.dispatchData(endpoint)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
