//
//  ViewModelAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

final class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        // Input Validator
        container.register(InputValidatorProtocol.self) { _ in
            InputValidator()
        }.inObjectScope(.container)
        
        // Auth ViewModel
        container.register(AuthViewModel.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let validator = r.resolve(InputValidatorProtocol.self)!
            return AuthViewModel(authRepository: authRepository, validator: validator)
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Product List ViewModel
        container.register(ProductListViewModel.self) { r in
            let productRepository = r.resolve(ProductRepositoryProtocol.self)!
            let cartRepository = r.resolve(CartRepositoryProtocol.self)!
            return ProductListViewModel(
                productRepository: productRepository,
                cartRepository: cartRepository
            )
        }.inObjectScope(.container) // Singleton para mantener estado consistente
        
        // Profile ViewModel
        container.register(ProfileViewModel.self) { r in
            let userRepository = r.resolve(UserRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return ProfileViewModel(
                userRepository: userRepository,
                authRepository: authRepository
            )
        }.inObjectScope(.container) // Singleton para mantener estado consistente
    }
}
