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
    func getAllCategories() -> AnyPublisher<[Category], Error>
}

final class ProductRepository: ProductRepositoryProtocol {
    private let productService: ProductServiceProtocol
    
    init(productService: ProductServiceProtocol) {
        self.productService = productService
    }
    
    func getAllProducts() -> AnyPublisher<[Product], Error> {
        print("ProductRepository: Getting all products")
        return productService.getAllProducts()
            .handleEvents(receiveOutput: { products in
                print("ProductRepository: Received \(products.count) products")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("ProductRepository: Failed to get products: \(error)")
                } else {
                    print("ProductRepository: Successfully completed products request")
                }
            })
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
    
    func getAllCategories() -> AnyPublisher<[Category], Error> {
        return productService.getAllCategories()
            .handleEvents(receiveOutput: { categories in
                print("ProductRepository: Received \(categories.count) categories")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("ProductRepository: Failed to get categories: \(error)")
                } else {
                    print("ProductRepository: Successfully completed categories request")
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
