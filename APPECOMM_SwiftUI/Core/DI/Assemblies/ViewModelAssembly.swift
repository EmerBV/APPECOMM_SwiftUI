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
        // Auth ViewModel
        container.register(AuthViewModel.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let validator = r.resolve(InputValidatorProtocol.self)!
            return AuthViewModel(authRepository: authRepository, validator: validator)
        }
        
        // Input Validator
        container.register(InputValidatorProtocol.self) { _ in
            InputValidator()
        }.inObjectScope(.container)
        
        // Product List ViewModel
        container.register(ProductListViewModel.self) { r in
            let productRepository = r.resolve(ProductRepositoryProtocol.self)!
            return ProductListViewModel(productRepository: productRepository)
        }
        
        // Profile ViewModel
        container.register(ProfileViewModel.self) { r in
            let userRepository = r.resolve(UserRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return ProfileViewModel(
                userRepository: userRepository,
                authRepository: authRepository
            )
        }
    }
}
