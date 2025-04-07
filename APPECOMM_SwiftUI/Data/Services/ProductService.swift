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
    func getAllCategories() -> AnyPublisher<[Category], NetworkError>
}

final class ProductService: ProductServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getAllProducts() -> AnyPublisher<[Product], NetworkError> {
        let endpoint = ProductEndpoints.getAllProducts
        
        // Registrar inicio de la petición
        Logger.debug("ProductService: Fetching all products")
        
        return networkDispatcher.dispatch(ApiResponse<[Product]>.self, endpoint)
            .map { response -> [Product] in
                Logger.info("ProductService: Successfully decoded response with \(response.data.count) products")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductService: Failed to get all products: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getProductById(id: Int) -> AnyPublisher<Product, NetworkError> {
        let endpoint = ProductEndpoints.getProductById(id: id)
        
        return networkDispatcher.dispatch(ApiResponse<Product>.self, endpoint)
            .map { response -> Product in
                Logger.info("ProductService: Successfully get product by id: \(response.data.name)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductService: Failed to get product by id: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], NetworkError> {
        let endpoint = ProductEndpoints.getProductsByCategory(category: category)
        
        return networkDispatcher.dispatch(ApiResponse<[Product]>.self, endpoint)
            .map { response -> [Product] in
                Logger.info("ProductService: Successfully get product by category")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductService: Failed to get products by category: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], NetworkError> {
        let endpoint = ProductEndpoints.getProductsByBrand(brand: brand)
        
        return networkDispatcher.dispatch(ApiResponse<[Product]>.self, endpoint)
            .map { response -> [Product] in
                Logger.info("ProductService: Successfully get products by brand")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductService: Failed to get products by brand: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getAllCategories() -> AnyPublisher<[Category], NetworkError> {
        let endpoint = ProductEndpoints.getAllCategories
        Logger.debug("ProductService: Fetching all categories")
        
        return networkDispatcher.dispatch(ApiResponse<[Category]>.self, endpoint)
            .map { response -> [Category] in
                Logger.info("ProductService: Successfully decoded response with \(response.data.count) categories")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductService: Failed to get all categories: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
