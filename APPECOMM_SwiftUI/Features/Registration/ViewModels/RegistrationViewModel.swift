//
//  RegistrationViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 24/4/25.
//

import Foundation
import Combine

class RegistrationViewModel: ObservableObject {
    // Input fields
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var acceptTerms: Bool = false
    
    // UI state
    @Published var isRegistering = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Field validation states
    @Published var firstNameState: FieldState = .normal
    @Published var lastNameState: FieldState = .normal
    @Published var emailState: FieldState = .normal
    @Published var passwordState: FieldState = .normal
    @Published var confirmPasswordState: FieldState = .normal
    @Published var termsState: FieldState = .normal
    
    // Dependencies
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var isFormValid: Bool {
        if case .invalid = firstNameState { return false }
        if case .invalid = lastNameState { return false }
        if case .invalid = emailState { return false }
        if case .invalid = passwordState { return false }
        if case .invalid = confirmPasswordState { return false }
        if !acceptTerms { return false }
        
        return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty &&
        !password.isEmpty && !confirmPassword.isEmpty &&
        password == confirmPassword
    }
    
    init(
        authRepository: AuthRepositoryProtocol,
        validator: InputValidatorProtocol
    ) {
        self.authRepository = authRepository
        self.validator = validator
    }
    
    // Validación de campos
    func validateFirstName() {
        let result = validator.validateName(firstName)
        switch result {
        case .valid:
            firstNameState = .valid
        case .invalid(let message):
            firstNameState = .invalid(message)
        }
    }
    
    func validateLastName() {
        let result = validator.validateName(lastName)
        switch result {
        case .valid:
            lastNameState = .valid
        case .invalid(let message):
            lastNameState = .invalid(message)
        }
    }
    
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
    
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordState = .invalid("password_confirmation_required".localized)
            return
        }
        
        if password != confirmPassword {
            confirmPasswordState = .invalid("passwords_do_not_match".localized)
            return
        }
        
        confirmPasswordState = .valid
    }
    
    func validateTerms() {
        if !acceptTerms {
            termsState = .invalid("must_accept_terms".localized)
            return
        }
        
        termsState = .valid
    }
    
    // Validar todos los campos a la vez
    func validateAllFields() {
        validateFirstName()
        validateLastName()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        validateTerms()
    }
    
    // Registro de usuario
    func register() {
        Logger.info("Iniciando proceso de registro")
        
        // Validar todos los campos antes de enviar
        validateAllFields()
        
        guard isFormValid else {
            Logger.warning("Formulario de registro no válido")
            NotificationService.shared.showError(
                title: "validation_error".localized,
                message: "form_errors".localized
            )
            return
        }
        
        isRegistering = true
        errorMessage = nil
        
        authRepository.register(firstName: firstName, lastName: lastName, email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isRegistering = false
                
                if case .failure(let error) = completion {
                    Logger.error("Registro fallido: \(error.localizedDescription)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .badRequest:
                            NotificationService.shared.showError(
                                title: "registration_error".localized,
                                message: "invalid_registration_details".localized
                            )
                        case .serverError:
                            NotificationService.shared.showError(
                                title: "server_error".localized,
                                message: "try_again_later".localized
                            )
                        default:
                            NotificationService.shared.showError(
                                title: "error".localized,
                                message: networkError.localizedDescription
                            )
                        }
                    } else {
                        NotificationService.shared.showError(
                            title: "error".localized,
                            message: error.localizedDescription
                        )
                    }
                    
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                guard let self = self else { return }
                
                Logger.info("Registro exitoso para usuario: \(user.id)")
                
                // Mostrar notificación de bienvenida
                NotificationService.shared.showSuccess(
                    title: "welcome".localized,
                    message: "account_created_success".localized
                )
                
                // Reiniciar el formulario
                self.resetForm()
            }
            .store(in: &cancellables)
    }
    
    private func resetForm() {
        firstName = ""
        lastName = ""
        email = ""
        password = ""
        confirmPassword = ""
        acceptTerms = false
        
        firstNameState = .normal
        lastNameState = .normal
        emailState = .normal
        passwordState = .normal
        confirmPasswordState = .normal
        termsState = .normal
    }
}
