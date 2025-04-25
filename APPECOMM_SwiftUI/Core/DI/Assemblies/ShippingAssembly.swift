//
//  ShippingAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 25/4/25.
//

import Foundation
import Swinject

/// Assembly for shipping-related dependencies
final class ShippingAssembly: Assembly {
    func assemble(container: Container) {
        // Register Shipping Service
        container.register(ShippingServiceProtocol.self) { r in
            let networkDispatcher = r.resolve(NetworkDispatcherProtocol.self)!
            return ShippingService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Register Shipping Repository
        container.register(ShippingRepositoryProtocol.self) { r in
            let shippingService = r.resolve(ShippingServiceProtocol.self)!
            return ShippingRepository(shippingService: shippingService)
        }.inObjectScope(.container)
        
        // Register ShippingAddressesViewModel - Usado para manejar múltiples direcciones
        container.register(ShippingAddressesViewModel.self) { r in
            let shippingRepository = r.resolve(ShippingRepositoryProtocol.self)!
            return ShippingAddressesViewModel(shippingRepository: shippingRepository)
        }.inObjectScope(.container)
    }
}
