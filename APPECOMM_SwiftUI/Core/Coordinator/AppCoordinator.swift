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
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .loggedIn(let user):
                    Logger.info("Usuario autenticado: \(user.id), navegando a la pantalla principal")
                    withAnimation {
                        self.currentScreen = .main
                    }
                case .loggedOut:
                    Logger.info("Usuario no autenticado, navegando a login")
                    withAnimation {
                        self.currentScreen = .login
                    }
                case .loading:
                    Logger.info("Verificando estado de autenticación")
                    withAnimation {
                        self.currentScreen = .splash
                    }
                }
            }
            .store(in: &cancellables)
        
        // Verificar estado de autenticación al inicio
        checkInitialAuthState()
    }
    
    private func checkInitialAuthState() {
        Task {
            do {
                try await authRepository.checkAuthStatus()
            } catch {
                Logger.error("Error al verificar estado de autenticación inicial: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.currentScreen = .login
                    }
                }
            }
        }
    }
}

enum AppScreen {
    case splash
    case login
    case main
}
