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
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
        
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .loggedIn:
                    self?.currentScreen = .main
                case .loggedOut:
                    self?.currentScreen = .login
                case .loading:
                    self?.currentScreen = .splash
                }
            }
            .store(in: &cancellables)
        
        // Verificar estado de autenticación al inicio
        checkAuth()
    }
    
    private func checkAuth() {
        // El repositorio de autenticación ya maneja esto internamente,
        // pero queremos asegurarnos de mostrar la pantalla de splash durante la verificación
        self.currentScreen = .splash
    }
}

enum AppScreen {
    case splash
    case login
    case main
}
