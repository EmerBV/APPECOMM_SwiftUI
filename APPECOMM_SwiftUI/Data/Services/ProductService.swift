//
//  ProductService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation
import Combine

protocol ProductServiceProtocol {
    func getAllProducts() -> AnyPublisher<[Product], NetworkError>
    func getProductById(id: Int) -> AnyPublisher<Product, NetworkError>
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], NetworkError>
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], NetworkError>
}

final class ProductService: ProductServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getAllProducts() -> AnyPublisher<[Product], NetworkError> {
        let endpoint = ProductEndpoints.getAllProducts
        
        // Registrar inicio de la petición
        print("ProductService: Fetching all products")
        
        return networkDispatcher.dispatch(ApiResponse<[Product]>.self, endpoint)
            .map { response -> [Product] in
                print("ProductService: Successfully decoded response with \(response.data.count) products")
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func getProductById(id: Int) -> AnyPublisher<Product, NetworkError> {
        let endpoint = ProductEndpoints.getProductById(id: id)
        
        return networkDispatcher.dispatch(ApiResponse<Product>.self, endpoint)
            .map { response -> Product in
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], NetworkError> {
        let endpoint = ProductEndpoints.getProductsByCategory(category: category)
        
        return networkDispatcher.dispatch(ApiResponse<[Product]>.self, endpoint)
            .map { response -> [Product] in
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], NetworkError> {
        let endpoint = ProductEndpoints.getProductsByBrand(brand: brand)
        
        return networkDispatcher.dispatch(ApiResponse<[Product]>.self, endpoint)
            .map { response -> [Product] in
                return response.data
            }
            .eraseToAnyPublisher()
    }
}
