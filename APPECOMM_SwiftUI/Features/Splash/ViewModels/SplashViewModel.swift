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
    @Published var statusMessage = "splash_initializing".localized
    @Published var error: String?
    
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func checkAuth() {
        isLoading = true
        statusMessage = "splash_checking_auth".localized
        error = nil
        
        authRepository.checkAuthStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.error = "splash_error_message".localized
                    Logger.error("Error en SplashView: \(error)")
                }
            } receiveValue: { [weak self] user in
                if user != nil {
                    self?.statusMessage = "splash_loading_data".localized
                } else {
                    self?.statusMessage = "splash_almost_there".localized
                }
                
                // La navegación se manejará por el AppCoordinator
            }
            .store(in: &cancellables)
    }
}
