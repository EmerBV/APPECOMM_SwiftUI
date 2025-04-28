//
//  HomeAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/4/25.
//

import Foundation
import Swinject

final class HomeAssembly: Assembly {
    func assemble(container: Container) {
        container.register(HomeViewModel.self) { r in
            let productRepository = r.resolve(ProductRepositoryProtocol.self)!
            return HomeViewModel(productRepository: productRepository)
        }.inObjectScope(.container)
    }
}
