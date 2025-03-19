//
//  AuthRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol AuthRepositoryProtocol {
    var authState: CurrentValueSubject<AuthState, Never> { get }
    
    func login(email: String, password: String) -> AnyPublisher<User, Error>
    func logout() -> AnyPublisher<Void, Error>
    func checkAuthStatus() -> AnyPublisher<User?, Error>
}

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

final class AuthRepository: AuthRepositoryProtocol {
    var authState: CurrentValueSubject<AuthState, Never> = CurrentValueSubject(.loggedOut)
    
    private static let userKey = "current_user"
    
    private let authService: AuthServiceProtocol
    private let tokenManager: TokenManagerProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authService: AuthServiceProtocol,
        tokenManager: TokenManagerProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.authService = authService
        self.tokenManager = tokenManager
        self.userDefaultsManager = userDefaultsManager
        
        // Verificar estado de autenticación inicial
        checkAuthStatus().sink { _ in
            // Ignorar errores
        } receiveValue: { [weak self] user in
            if let user = user {
                self?.authState.send(.loggedIn(user))
            } else {
                self?.authState.send(.loggedOut)
            }
        }
        .store(in: &cancellables)
    }
    
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        authState.send(.loading)
        
        return authService.login(email: email, password: password)
            .tryMap { [weak self] response -> AuthToken in
                guard let self = self else {
                    throw NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])
                }
                
                try self.tokenManager.saveTokens(
                    accessToken: response.data.token,
                    refreshToken: nil, // La API no devuelve refresh token
                    userId: response.data.id
                )
                
                return response.data
            }
            .flatMap { [weak self] authToken -> AnyPublisher<User, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])).eraseToAnyPublisher()
                }
                
                // Crear un usuario ficticio para esta demostración
                // En un caso real, haríamos una llamada al servidor para obtener los datos completos del usuario
                let user = User(
                    id: authToken.id,
                    firstName: "Usuario",
                    lastName: "De Prueba",
                    email: email,
                    shippingDetails: nil,
                    cart: nil,
                    orders: nil
                )
                
                // Guardar el usuario en UserDefaults
                self.userDefaultsManager.save(object: user, forKey: Self.userKey)
                
                self.authState.send(.loggedIn(user))
                
                return Just(user)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        // Idealmente, también realizaríamos una llamada al servidor para invalidar el token
        // Para simplificar, solo eliminamos los datos locales
        do {
            try tokenManager.clearTokens()
            userDefaultsManager.remove(forKey: Self.userKey)
            authState.send(.loggedOut)
            
            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    func checkAuthStatus() -> AnyPublisher<User?, Error> {
        if !tokenManager.hasValidToken() {
            return Just(nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Intentar obtener el usuario almacenado
        if let user: User = userDefaultsManager.get(objectType: User.self, forKey: Self.userKey) {
            return Just(user)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Si tenemos token pero no usuario, intentaríamos obtener el usuario del servidor
        // Para simplificar, asumimos que si no tenemos usuario local, no hay sesión
        return Just(nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
