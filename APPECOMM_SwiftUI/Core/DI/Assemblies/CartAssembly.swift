//
//  CartAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/4/25.
//

import Foundation
import Swinject

final class CartAssembly: Assembly {
    func assemble(container: Container) {
        container.register(CartViewModel.self) { r in
            let cartRepository = r.resolve(CartRepositoryProtocol.self)!
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            return CartViewModel(
                cartRepository: cartRepository,
                authRepository: authRepository
            )
        }.inObjectScope(.container)
    }
}
