//
//  AppCoordinator.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine
import SwiftUI

class AppCoordinator: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol, tokenManager: TokenManagerProtocol) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .loggedIn(let user):
                    Logger.info("Usuario logueado: \(user.id), cambiando a pantalla principal")
                    self.currentScreen = .main
                    
                    // Send a notification to pre-load data for the home view
                    NotificationCenter.default.post(
                        name: Notification.Name("UserLoggedInPreloadHome"),
                        object: nil,
                        userInfo: ["userId": user.id]
                    )
                case .loggedOut:
                    Logger.info("Usuario deslogueado, cambiando a pantalla de login")
                    self.currentScreen = .login
                case .loading:
                    Logger.info("Estado de autenticación cargando, cambiando a splash")
                    self.currentScreen = .splash
                }
            }
            .store(in: &cancellables)
        
        // Verificar estado de autenticación al inicio
        checkAuth()
    }
    
    private func checkAuth() {
        Logger.info("Verificando estado de autenticación...")
        
        // Si tenemos un token válido, intentamos obtener el usuario
        if tokenManager.hasValidToken() {
            Logger.info("Token válido encontrado, verificando usuario...")
            
            // Verificar si hay un usuario guardado
            authRepository.checkAuthStatus()
                .sink { completion in
                    if case .failure(let error) = completion {
                        Logger.error("Error al verificar estado de autenticación: \(error)")
                        self.currentScreen = .login
                    }
                } receiveValue: { [weak self] user in
                    if let user = user {
                        Logger.info("Usuario recuperado correctamente: \(user.id)")
                        self?.currentScreen = .main
                        
                        // Also trigger home data preload
                        NotificationCenter.default.post(
                            name: Notification.Name("UserLoggedInPreloadHome"),
                            object: nil,
                            userInfo: ["userId": user.id]
                        )
                    } else {
                        Logger.warning("No se encontró información de usuario a pesar de tener token")
                        self?.currentScreen = .login
                    }
                }
                .store(in: &cancellables)
        } else {
            Logger.info("No hay token válido, redirigiendo a login")
            currentScreen = .login
        }
    }
}

enum AppScreen {
    case splash
    case login
    case main
}
