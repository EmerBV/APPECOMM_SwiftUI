//
//  ProductAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 25/4/25.
//

import Foundation
import Swinject

/// Assembly for product-related dependencies
/// TODO
/*
 ProductDetailViewModel - Detalle de un producto
 ProductSearchViewModel - Búsqueda de productos
 CategoryViewModel - Categorías de productos
 */

final class ProductAssembly: Assembly {
    func assemble(container: Container) {
        // Product List ViewModel
        container.register(ProductListViewModel.self) { r in
            let productRepository = r.resolve(ProductRepositoryProtocol.self)!
            let cartRepository = r.resolve(CartRepositoryProtocol.self)!
            return ProductListViewModel(
                productRepository: productRepository,
                cartRepository: cartRepository
            )
        }.inObjectScope(.container)
    }
}

