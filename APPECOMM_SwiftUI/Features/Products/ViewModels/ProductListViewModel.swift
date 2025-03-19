//
//  ProductViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation
import Combine
import SwiftUI

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productService: ProductServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(productService: ProductServiceProtocol = ProductService()) {
        self.productService = productService
    }
    
    func loadProducts() {
        isLoading = true
        errorMessage = nil
        
        productService.fetchProducts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] products in
                self?.products = products
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: NetworkError) {
        switch error {
        case .invalidURL:
            errorMessage = "URL inválida"
        case .invalidResponse:
            errorMessage = "Respuesta inválida del servidor"
        case .invalidData:
            errorMessage = "Datos inválidos"
        case .serverError(let message):
            errorMessage = "Error del servidor: \(message)"
        case .decodingError:
            errorMessage = "Error al procesar la respuesta"
        case .unknown:
            errorMessage = "Error desconocido"
        }
    }
    
    // Formato de precio con símbolo de moneda
    func formattedPrice(for product: Product) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        
        if let formattedPrice = formatter.string(from: product.price as NSDecimalNumber) {
            return formattedPrice
        }
        return "$\(product.price)"
    }
    
    // Calcular precio con descuento
    func discountedPrice(for product: Product) -> Decimal? {
        guard product.discountPercentage > 0 else { return nil }
        let discount = product.price * Decimal(product.discountPercentage) / 100
        return product.price - discount
    }
    
    // Formato para precio con descuento
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
