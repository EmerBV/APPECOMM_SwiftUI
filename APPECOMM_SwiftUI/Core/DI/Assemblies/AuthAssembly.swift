//
//  AuthAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 25/4/25.
//

import Foundation
import Swinject

/// Assembly for auth-related dependencies
final class AuthAssembly: Assembly {
    func assemble(container: Container) {
        // Auth ViewModel
        container.register(AuthViewModel.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let validator = r.resolve(InputValidatorProtocol.self)!
            return AuthViewModel(authRepository: authRepository, validator: validator)
        }.inObjectScope(.container)
        
        // Registration ViewModel
        container.register(RegistrationViewModel.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let validator = r.resolve(InputValidatorProtocol.self)!
            return RegistrationViewModel(
                authRepository: authRepository,
                validator: validator
            )
        }.inObjectScope(.transient)
        
        // Profile ViewModel
        container.register(ProfileViewModel.self) { r in
            let userRepository = r.resolve(UserRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return ProfileViewModel(
                userRepository: userRepository,
                authRepository: authRepository
            )
        }.inObjectScope(.container)
    }
}
