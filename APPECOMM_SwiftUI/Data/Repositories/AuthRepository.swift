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
    
    func debugAuthState()
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
        print("AuthRepository: Starting login process")
        authState.send(.loading)
        
        return authService.login(email: email, password: password)
            .map { authToken -> AuthToken in
                print("AuthRepository: Processing login response")
                try? self.tokenManager.saveTokens(
                    accessToken: authToken.token,
                    refreshToken: nil,
                    userId: authToken.id
                )
                
                return authToken
            }
            .map { authToken -> User in
                print("AuthRepository: Creating user object for ID: \(authToken.id)")
                
                // Crear un usuario con los datos que tenemos
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
                
                print("AuthRepository: Sending loggedIn state with user ID: \(user.id)")
                self.authState.send(.loggedIn(user))
                
                return user
            }
            .mapError { error -> Error in
                print("AuthRepository: Login failed with error: \(error)")
                self.authState.send(.loggedOut)
                return error
            }
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
    
    func debugAuthState() {
        // Verificar el token
        print("DEBUG: Token exists: \(tokenManager.hasValidToken())")
        
        // Verificar el usuario guardado
        if let user: User = userDefaultsManager.get(objectType: User.self, forKey: Self.userKey) {
            print("DEBUG: User exists: \(user.id) - \(user.email)")
        } else {
            print("DEBUG: No user found in storage")
        }
        
        // Estado actual
        let currentAuthState = authState.value
        print("DEBUG: Current auth state: \(currentAuthState)")
    }
}
