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
    private let userService: UserServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authService: AuthServiceProtocol,
        tokenManager: TokenManagerProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        userService: UserServiceProtocol
    ) {
        self.authService = authService
        self.tokenManager = tokenManager
        self.userDefaultsManager = userDefaultsManager
        self.userService = userService
        
        // Verificar estado de autenticación inicial
        checkAuthStatus().sink { completion in
            if case .failure(let error) = completion {
                Logger.error("Error al verificar estado de autenticación: \(error)")
            }
        } receiveValue: { [weak self] user in
            if let user = user {
                Logger.info("Usuario existente encontrado: \(user.id)")
                self?.authState.send(.loggedIn(user))
            } else {
                Logger.info("No se encontró usuario, estado: deslogueado")
                self?.authState.send(.loggedOut)
            }
        }
        .store(in: &cancellables)
    }
    
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        Logger.info("Iniciando proceso de login para email: \(email)")
        authState.send(.loading)
        
        return authService.login(email: email, password: password)
        // Primero convertir NetworkError a Error genérico
            .mapError { $0 as Error }  // Esto resuelve el problema de tipo
            .flatMap { [weak self] authToken -> AnyPublisher<User, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"])).eraseToAnyPublisher()
                }
                
                Logger.info("Login exitoso, guardando token para usuario ID: \(authToken.id)")
                
                // Guardar el token
                do {
                    try self.tokenManager.saveTokens(
                        accessToken: authToken.token,
                        refreshToken: nil, // Normalmente aquí se guardaría también el refreshToken
                        userId: authToken.id
                    )
                } catch {
                    Logger.error("Error al guardar tokens: \(error)")
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                // Obtener el perfil completo del usuario
                return self.userService.getUserProfile(userId: authToken.id)
                // También convertir NetworkError a Error para el servicio de usuario
                    .mapError { $0 as Error }
                    .map { user -> User in
                        Logger.info("Perfil de usuario obtenido correctamente: \(user.id)")
                        
                        // Guardar el usuario en UserDefaults
                        self.userDefaultsManager.save(object: user, forKey: Self.userKey)
                        
                        // Actualizar el estado de autenticación
                        self.authState.send(.loggedIn(user))
                        
                        return user
                    }
                    .catch { error -> AnyPublisher<User, Error> in
                        Logger.error("Error al obtener perfil de usuario: \(error)")
                        
                        // Si falla, al menos creamos un usuario básico con el ID y email
                        let basicUser = User(
                            id: authToken.id,
                            firstName: "Usuario",
                            lastName: "Temporal",
                            email: email,
                            shippingDetails: nil,
                            cart: nil,
                            orders: nil
                        )
                        
                        // Guardar usuario básico
                        self.userDefaultsManager.save(object: basicUser, forKey: Self.userKey)
                        self.authState.send(.loggedIn(basicUser))
                        
                        return Just(basicUser)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .mapError { error -> Error in
                Logger.error("Error en el proceso de login: \(error)")
                self.authState.send(.loggedOut)
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        Logger.info("Iniciando proceso de logout")
        
        // Primero intentamos hacer logout en el servidor
        return authService.logout()
            .catch { error -> AnyPublisher<Void, Error> in
                // Si falla el logout en el servidor, continuamos con el logout local
                Logger.warning("Error al hacer logout en servidor: \(error). Continuando con logout local.")
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"])).eraseToAnyPublisher()
                }
                
                do {
                    // Limpiamos datos locales
                    try self.tokenManager.clearTokens()
                    self.userDefaultsManager.remove(forKey: Self.userKey)
                    self.authState.send(.loggedOut)
                    
                    Logger.info("Logout completado con éxito")
                    
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                } catch {
                    Logger.error("Error durante el logout local: \(error)")
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func checkAuthStatus() -> AnyPublisher<User?, Error> {
        Logger.info("Verificando estado de autenticación")
        
        // Si no hay token válido, no hay sesión
        if !tokenManager.hasValidToken() {
            Logger.info("No hay token válido")
            return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        // Intentar obtener el usuario almacenado
        if let user: User = userDefaultsManager.get(objectType: User.self, forKey: Self.userKey) {
            Logger.info("Usuario encontrado en almacenamiento local: \(user.id)")
            
            // Si el usuario tiene más de 24 horas almacenado, refrescamos su información
            if shouldRefreshUserInfo() {
                Logger.info("Refrescando información del usuario desde el servidor")
                return refreshUserInfo(user)
            }
            
            return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        // Si tenemos token pero no usuario, intentamos obtener el usuario del servidor
        // basándonos en el ID almacenado en el token
        if let userId = tokenManager.getUserId() {
            Logger.info("Token válido pero sin usuario local. Obteniendo usuario del servidor ID: \(userId)")
            
            return userService.getUserProfile(userId: userId)
                .map { user -> User in
                    // Guardar el usuario obtenido
                    self.userDefaultsManager.save(object: user, forKey: Self.userKey)
                    return user
                }
                .mapError { error -> Error in
                    Logger.error("Error al obtener perfil de usuario: \(error)")
                    return error
                }
                .eraseToAnyPublisher()
        }
        
        // No pudimos obtener ni ID de usuario
        Logger.warning("Token válido pero sin ID de usuario")
        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    private func shouldRefreshUserInfo() -> Bool {
        // Comprobamos cuándo fue la última vez que actualizamos la info del usuario
        if let lastUpdate = userDefaultsManager.getDate(forKey: "last_user_info_update") {
            let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
            return lastUpdate < twentyFourHoursAgo
        }
        
        return true // Si no hay fecha, refrescamos
    }
    
    private func refreshUserInfo(_ user: User) -> AnyPublisher<User?, Error> {
        return userService.getUserProfile(userId: user.id)
            .map { updatedUser -> User? in
                // Actualizar fecha de última actualización
                self.userDefaultsManager.save(value: Date(), forKey: "last_user_info_update")
                
                // Guardar usuario actualizado
                self.userDefaultsManager.save(object: updatedUser, forKey: Self.userKey)
                
                return updatedUser
            }
            .catch { error -> AnyPublisher<User?, Error> in
                // Si falla la actualización, seguimos usando el usuario que teníamos
                Logger.warning("Error al refrescar info de usuario: \(error). Usando datos locales.")
                return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func debugAuthState() {
        // Verificar el token
        Logger.debug("Token existe: \(tokenManager.hasValidToken())")
        
        // Verificar el usuario guardado
        if let user: User = userDefaultsManager.get(objectType: User.self, forKey: Self.userKey) {
            Logger.debug("Usuario existe: \(user.id) - \(user.email)")
        } else {
            Logger.debug("No se encontró usuario en almacenamiento")
        }
        
        // Estado actual
        let currentAuthState = authState.value
        Logger.debug("Estado de autenticación actual: \(currentAuthState)")
    }
}
