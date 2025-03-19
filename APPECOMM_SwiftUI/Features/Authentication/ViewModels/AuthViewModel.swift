//
//  AuthViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // Input fields
    @Published var email: String = ""
    @Published var password: String = ""
    
    // UI state
    @Published var isLoginInProgress = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Field validation states
    @Published var emailState: FieldState = .normal
    @Published var passwordState: FieldState = .normal
    
    // Dependencies
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var isFormValid: Bool {
        if case .invalid = emailState { return false }
        if case .invalid = passwordState { return false }
        return !email.isEmpty && !password.isEmpty
    }
    
    init(authRepository: AuthRepositoryProtocol, validator: InputValidatorProtocol) {
        self.authRepository = authRepository
        self.validator = validator
        
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .loading = state {
                    self?.isLoginInProgress = true
                } else {
                    self?.isLoginInProgress = false
                }
            }
            .store(in: &cancellables)
    }
    
    // Validación de campos
    func validateEmail() {
        let result = validator.validateEmail(email)
        switch result {
        case .valid:
            emailState = .valid
        case .invalid(let message):
            emailState = .invalid(message)
        }
    }
    
    func validatePassword() {
        let result = validator.validatePassword(password)
        switch result {
        case .valid:
            passwordState = .valid
        case .invalid(let message):
            passwordState = .invalid(message)
        }
    }
    
    // Acciones
    func login() {
        print("AuthViewModel: Starting login process")
        // Validar todos los campos antes de enviar
        validateEmail()
        validatePassword()
        
        guard isFormValid else {
            print("AuthViewModel: Form validation failed")
            return
        }
        
        isLoginInProgress = true
        errorMessage = nil
        
        authRepository.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("AuthViewModel: Login process completed")
                self?.isLoginInProgress = false
                
                if case .failure(let error) = completion {
                    print("AuthViewModel: Login failed with error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                print("AuthViewModel: Login succeeded for user ID: \(user.id)")
                self?.successMessage = "Login successful"
                self?.resetForm()
                
                // Notificar explícitamente el login exitoso
                NotificationCenter.default.post(name: Notification.Name("UserLoggedIn"), object: user)
            }
            .store(in: &cancellables)
    }
    
    private func resetForm() {
        email = ""
        password = ""
        emailState = .normal
        passwordState = .normal
    }
}
