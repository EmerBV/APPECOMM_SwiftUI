//
//  SplashViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

class SplashViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var statusMessage = "Verificando sesión..."
    @Published var error: String?
    
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func checkAuth() {
        isLoading = true
        statusMessage = "Verificando sesión..."
        error = nil
        
        authRepository.checkAuthStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.error = "No se pudo verificar la sesión: \(error.localizedDescription)"
                    Logger.error("Error en SplashView: \(error)")
                }
            } receiveValue: { [weak self] user in
                if user != nil {
                    self?.statusMessage = "Iniciando sesión..."
                } else {
                    self?.statusMessage = "Preparando aplicación..."
                }
                
                // La navegación se manejará por el AppCoordinator
            }
            .store(in: &cancellables)
    }
}
