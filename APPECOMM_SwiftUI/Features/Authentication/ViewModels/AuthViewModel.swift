//
//  AuthViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine
import LocalAuthentication

class AuthViewModel: ObservableObject {
    // Input fields
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    
    // UI state
    @Published var isLoginInProgress = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Alert state
    @Published var showAuthAlert = false
    @Published var authAlertTitle = ""
    @Published var authAlertMessage = ""
    
    // Field validation states
    @Published var emailState: FieldState = .normal
    @Published var passwordState: FieldState = .normal
    
    // Biometric authentication
    @Published var isBiometricAvailable = false
    @Published var biometricType: UIBiometricType = .none
    
    // Dependencies
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let secureStorage: SecureStorageProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // Keys para almacenamiento
    private let emailKey = "last_email"
    private let credentialsKey = "saved_credentials"
    
    // Computed properties
    var isFormValid: Bool {
        if case .invalid = emailState { return false }
        if case .invalid = passwordState { return false }
        return !email.isEmpty && !password.isEmpty
    }
    
    init(
        authRepository: AuthRepositoryProtocol,
        validator: InputValidatorProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol = DependencyInjector.shared.resolve(UserDefaultsManagerProtocol.self),
        secureStorage: SecureStorageProtocol = DependencyInjector.shared.resolve(SecureStorageProtocol.self)
    ) {
        self.authRepository = authRepository
        self.validator = validator
        self.userDefaultsManager = userDefaultsManager
        self.secureStorage = secureStorage
        
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
        
        // Restaurar último email usado
        if let savedEmail = userDefaultsManager.getString(forKey: emailKey) {
            self.email = savedEmail
        }
        
        // Verificar disponibilidad de autenticación biométrica
        checkBiometricAvailability()
        
        // Intentar restaurar credenciales guardadas
        loadSavedCredentials()
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
        Logger.info("Iniciando proceso de login")
        // Validar todos los campos antes de enviar
        validateEmail()
        validatePassword()
        
        guard isFormValid else {
            Logger.warning("Formulario de login no válido")
            showAlert(title: "Error de validación", message: "Por favor, corrija los errores del formulario")
            return
        }
        
        isLoginInProgress = true
        errorMessage = nil
        
        // Guardar el email usado para futuras sesiones
        userDefaultsManager.save(value: email, forKey: emailKey)
        
        authRepository.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoginInProgress = false
                
                if case .failure(let error) = completion {
                    Logger.error("Login fallido: \(error.localizedDescription)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .unauthorized:
                            self?.showAlert(title: "Error de autenticación", message: "Email o contraseña incorrectos")
                        case .serverError:
                            self?.showAlert(title: "Error del servidor", message: "Por favor, intente más tarde")
                        default:
                            self?.showAlert(title: "Error", message: networkError.localizedDescription)
                        }
                    } else {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            } receiveValue: { [weak self] user in
                guard let self = self else { return }
                
                Logger.info("Login exitoso para usuario: \(user.id)")
                self.successMessage = "Login exitoso"
                
                // Si el usuario marcó "recordarme", guardar credenciales
                if self.rememberMe {
                    self.saveCredentials()
                }
                
                // Reiniciar el formulario
                self.resetForm()
                
                // Notificar explícitamente el login exitoso
                NotificationCenter.default.post(name: Notification.Name("UserLoggedIn"), object: user)
                
                // Mostrar notificación de bienvenida
                NotificationService.shared.showSuccess(
                    title: "¡Bienvenido!",
                    message: "Hola \(user.firstName), has iniciado sesión correctamente"
                )
            }
            .store(in: &cancellables)
    }
    
    func loginWithBiometrics() {
        guard let credentials = retrieveCredentials() else {
            Logger.warning("No hay credenciales guardadas para login biométrico")
            showAlert(title: "Error", message: "No hay credenciales guardadas para inicio de sesión biométrico")
            return
        }
        
        isLoginInProgress = true
        errorMessage = nil
        
        // Usar las credenciales guardadas para iniciar sesión
        authRepository.login(email: credentials.email, password: credentials.password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoginInProgress = false
                
                if case .failure(let error) = completion {
                    Logger.error("Login biométrico fallido: \(error.localizedDescription)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .unauthorized:
                            self?.showAlert(title: "Error de autenticación", message: "Las credenciales guardadas han expirado. Por favor, inicie sesión nuevamente.")
                        case .serverError:
                            self?.showAlert(title: "Error del servidor", message: "Por favor, intente más tarde")
                        default:
                            self?.showAlert(title: "Error", message: networkError.localizedDescription)
                        }
                    } else {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            } receiveValue: { [weak self] user in
                Logger.info("Login biométrico exitoso para usuario: \(user.id)")
                self?.successMessage = "Login exitoso"
                
                // Notificar explícitamente el login exitoso
                NotificationCenter.default.post(name: Notification.Name("UserLoggedIn"), object: user)
                
                // Mostrar notificación de bienvenida
                NotificationService.shared.showSuccess(
                    title: "¡Bienvenido!",
                    message: "Hola \(user.firstName), has iniciado sesión correctamente con autenticación biométrica"
                )
            }
            .store(in: &cancellables)
    }
    
    private func resetForm() {
        email = ""
        password = ""
        emailState = .normal
        passwordState = .normal
        rememberMe = false
    }
    
    private func showAlert(title: String, message: String) {
        authAlertTitle = title
        authAlertMessage = message
        showAuthAlert = true
    }
    
    // Biometric authentication
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Determinar el tipo de biometría disponible
            switch context.biometryType {
            case .faceID:
                isBiometricAvailable = true
                biometricType = .face
                Logger.debug("Face ID disponible")
            case .touchID:
                isBiometricAvailable = true
                biometricType = .touch
                Logger.debug("Touch ID disponible")
            default:
                isBiometricAvailable = false
                biometricType = .none
                Logger.debug("No hay biometría disponible")
            }
        } else {
            isBiometricAvailable = false
            biometricType = .none
            if let error = error {
                Logger.warning("Error al verificar biometría: \(error.localizedDescription)")
            }
        }
    }
    
    // Credenciales guardadas
    private func saveCredentials() {
        do {
            let credentials = SavedCredentials(email: email, password: password)
            try secureStorage.saveObject(credentials, forKey: credentialsKey)
            Logger.info("Credenciales guardadas exitosamente")
        } catch {
            Logger.error("Error al guardar credenciales: \(error.localizedDescription)")
        }
    }
    
    private func loadSavedCredentials() {
        if let credentials: SavedCredentials = try? secureStorage.getObject(forKey: credentialsKey) {
            email = credentials.email
            // No establecemos la contraseña en la interfaz por seguridad
            // Pero marcamos "recordarme" para indicar que hay credenciales guardadas
            rememberMe = true
            Logger.debug("Credenciales cargadas, usuario: \(credentials.email)")
        }
    }
    
    private func retrieveCredentials() -> SavedCredentials? {
        return try? secureStorage.getObject(forKey: credentialsKey)
    }
}

struct SavedCredentials: Codable {
    let email: String
    let password: String
}
