//
//  ProductListViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation
import Combine

class ProductListViewModel: ObservableObject {
    // Published properties
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filtrado y búsqueda
    @Published var searchText = ""
    @Published var selectedCategory: String?
    
    // Computed properties
    var filteredProducts: [Product] {
        var result = products
        
        // Filtrar por categoría
        if let category = selectedCategory, !category.isEmpty {
            result = result.filter { $0.category.name == category }
        }
        
        // Filtrar por texto de búsqueda
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.description?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return result
    }
    
    var categories: [String] {
        let categoryNames = Set(products.map { $0.category.name })
        return Array(categoryNames).sorted()
    }
    
    // Dependencies
    private let productRepository: ProductRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(productRepository: ProductRepositoryProtocol) {
        self.productRepository = productRepository
    }
    
    func loadProducts() {
        print("ProductListViewModel: Loading products")
        isLoading = true
        errorMessage = nil
        
        productRepository.getAllProducts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    print("ProductListViewModel: Error loading products: \(error)")
                    
                    // Mensajes de error más específicos basados en el tipo de error
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .decodingError:
                            self?.errorMessage = "Error al procesar la respuesta. Formato inesperado de datos."
                        case .serverError:
                            self?.errorMessage = "Error del servidor. Intente más tarde."
                        case .unauthorized:
                            self?.errorMessage = "Sesión expirada. Inicie sesión nuevamente."
                        default:
                            self?.errorMessage = networkError.localizedDescription
                        }
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                } else {
                    print("ProductListViewModel: Products loaded successfully")
                }
            } receiveValue: { [weak self] products in
                print("ProductListViewModel: Received \(products.count) products")
                self?.products = products
            }
            .store(in: &cancellables)
    }
    
    func loadProductsByCategory(category: String) {
        isLoading = true
        errorMessage = nil
        
        productRepository.getProductsByCategory(category: category)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] products in
                self?.products = products
                self?.selectedCategory = category
            }
            .store(in: &cancellables)
    }
    
    // Formateo de precios
    func formattedPrice(for product: Product) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        
        if let formattedPrice = formatter.string(from: product.price as NSDecimalNumber) {
            return formattedPrice
        }
        return "$\(product.price)"
    }
    
    func discountedPrice(for product: Product) -> Decimal? {
        guard product.discountPercentage > 0 else { return nil }
        
        let discount = product.price * Decimal(product.discountPercentage) / 100
        return product.price - discount
    }
    
    func formattedDiscountedPrice(for product: Product) -> String? {
        guard let discountedPrice = discountedPrice(for: product) else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        
        if let formattedPrice = formatter.string(from: discountedPrice as NSDecimalNumber) {
            return formattedPrice
        }
        return "$\(discountedPrice)"
    }
}
