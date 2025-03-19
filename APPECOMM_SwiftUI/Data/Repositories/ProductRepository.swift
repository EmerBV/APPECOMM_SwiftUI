//
//  ProductRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol ProductRepositoryProtocol {
    func getAllProducts() -> AnyPublisher<[Product], Error>
    func getProductById(id: Int) -> AnyPublisher<Product, Error>
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], Error>
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], Error>
}

final class ProductRepository: ProductRepositoryProtocol {
    private let productService: ProductServiceProtocol
    
    init(productService: ProductServiceProtocol) {
        self.productService = productService
    }
    
    func getAllProducts() -> AnyPublisher<[Product], Error> {
        return productService.getAllProducts()
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getProductById(id: Int) -> AnyPublisher<Product, Error> {
        return productService.getProductById(id: id)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], Error> {
        return productService.getProductsByCategory(category: category)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], Error> {
        return productService.getProductsByBrand(brand: brand)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
