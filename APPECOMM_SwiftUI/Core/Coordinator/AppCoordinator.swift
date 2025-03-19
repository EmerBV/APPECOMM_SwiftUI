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
        
        print("AppCoordinator: Initializing")
        
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                print("AppCoordinator: Received auth state: \(state)")
                
                switch state {
                case .loggedIn(let user):
                    print("AppCoordinator: User logged in: \(user.id), setting screen to main")
                    DispatchQueue.main.async {
                        self?.currentScreen = .main
                        print("AppCoordinator: Screen set to main")
                        self?.setupFailsafeTimer()
                    }
                case .loggedOut:
                    print("AppCoordinator: User logged out, setting screen to login")
                    DispatchQueue.main.async {
                        self?.currentScreen = .login
                        print("AppCoordinator: Screen set to login")
                    }
                case .loading:
                    print("AppCoordinator: Auth state loading, setting screen to splash")
                    DispatchQueue.main.async {
                        self?.currentScreen = .splash
                        print("AppCoordinator: Screen set to splash")
                    }
                }
            }
            .store(in: &cancellables)
        
        // Verificar estado de autenticación al inicio
        checkAuth()
    }
    
    private func checkAuth() {
        print("AppCoordinator: Checking auth status...")
    }
    
    private func setupFailsafeTimer() {
        // Si después de 3 segundos todavía estamos en la pantalla de splash después de un login exitoso
        // forzar la transición a la pantalla principal
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            
            if case .splash = self.currentScreen, self.tokenManager.hasValidToken() {
                print("AppCoordinator: Failsafe triggered - Forcing transition to main")
                self.currentScreen = .main
            }
        }
    }
    
    
}

enum AppScreen {
    case splash
    case login
    case main
}
