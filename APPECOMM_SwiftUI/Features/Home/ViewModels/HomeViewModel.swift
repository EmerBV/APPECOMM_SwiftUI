//
//  HomeViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 20/3/25.
//

import Foundation
import Combine
import SwiftUI

class HomeViewModel: ObservableObject {
    // Published properties
    @Published var newProducts: [Product] = []
    @Published var bestSellingProducts: [Product] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let productRepository: ProductRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Product List ViewModel
    let productListViewModel: ProductListViewModel
    
    init(productRepository: ProductRepositoryProtocol) {
        self.productRepository = productRepository
        self.productListViewModel = DependencyInjector.shared.resolve(ProductListViewModel.self)
        
        // Set up notification observer for user login
        NotificationCenter.default.publisher(for: Notification.Name("UserLoggedInPreloadHome"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Logger.info("Received user login notification, preloading Home data")
                Task { @MainActor in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func loadInitialDataIfNeeded() async {
        guard newProducts.isEmpty && bestSellingProducts.isEmpty && categories.isEmpty else { return }
        await loadData()
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    @MainActor
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load categories
            let categoriesPublisher = productRepository.getAllCategories()
            for try await categories in categoriesPublisher.values {
                self.categories = categories.sorted(by: { $0.name < $1.name })
                Logger.info("Loaded \(self.categories.count) categories from API")
                break
            }
            
            // Load products
            let productsPublisher = productRepository.getAllProducts()
            for try await products in productsPublisher.values {
                // Process recent products (newest first)
                self.newProducts = products
                    .sorted(by: { compareCreationDates($0.createdAt, $1.createdAt) })
                    .prefix(10)
                    .map { $0 }
                Logger.info("Loaded \(self.newProducts.count) recent products")
                
                // Process best selling products
                self.bestSellingProducts = products
                    .sorted(by: { $0.salesCount > $1.salesCount })
                    .prefix(10)
                    .map { $0 }
                Logger.info("Loaded \(self.bestSellingProducts.count) best selling products")
                break
            }
            
        } catch {
            Logger.error("Error loading data: \(error)")
            self.errorMessage = "failed_to_load_data".localized
        }
        
        isLoading = false
        Logger.info("Home data loading completed")
    }
    
    // Helper function to compare creation dates
    private func compareCreationDates(_ date1: String, _ date2: String) -> Bool {
        guard let date1 = APPFormatters.parseDate(date1),
              let date2 = APPFormatters.parseDate(date2) else {
            Logger.warning("No se pudieron parsear las fechas: \(date1) o \(date2)")
            return false
        }
        
        return date1 > date2 // Sort newest first
    }
    
    func discountedPrice(for product: Product) -> Decimal {
        let discount = product.price * Decimal(product.discountPercentage) / 100
        return (product.price - discount).rounded(2)
    }
    
    func formattedDiscountedPrice(for product: Product) -> String {
        let discountedPrice = discountedPrice(for: product)
        return discountedPrice.toCurrentLocalePrice
    }
}
