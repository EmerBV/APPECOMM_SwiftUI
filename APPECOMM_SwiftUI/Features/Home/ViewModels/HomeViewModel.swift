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
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let productRepository: ProductRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Formatters - reused for better performance
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter
    }()
    
    init(productRepository: ProductRepositoryProtocol) {
        self.productRepository = productRepository
        
        // Pre-load product categories for our featured section
        categories = ["Dragon Ball", "One Piece", "Naruto", "Demon Slayer",
                      "Jujutsu Kaisen", "Bleach", "Chainsaw Man", "Spy x Family"]
        
        // Set up notification observer for user login
        NotificationCenter.default.publisher(for: Notification.Name("UserLoggedInPreloadHome"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Logger.info("Received user login notification, preloading Home data")
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Using a dispatch group to coordinate multiple requests
        let dispatchGroup = DispatchGroup()
        
        // Load recent products
        dispatchGroup.enter()
        loadRecentProducts { [weak self] in
            dispatchGroup.leave()
        }
        
        // Load best sellers
        dispatchGroup.enter()
        loadBestSellingProducts { [weak self] in
            dispatchGroup.leave()
        }
        
        // When both requests complete, update the UI
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            Logger.info("Home data loading completed")
        }
    }
    
    private func loadRecentProducts(completion: @escaping () -> Void) {
        Logger.info("Loading recent products")
        
        productRepository.getAllProducts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionStatus in
                if case .failure(let error) = completionStatus {
                    Logger.error("Error loading recent products: \(error)")
                    self?.errorMessage = "Failed to load new products: \(error.localizedDescription)"
                }
                completion()
            } receiveValue: { [weak self] products in
                // Sort products by creation date (newest first) and take up to 10
                self?.newProducts = products
                    .sorted(by: { self?.compareCreationDates($0.createdAt, $1.createdAt) ?? false })
                    .prefix(10)
                    .map { $0 }
                
                Logger.info("Loaded \(self?.newProducts.count ?? 0) recent products")
                
                // Extract categories for the featured section if not already populated
                let categories = Set(products.map { $0.category.name })
                if !categories.isEmpty {
                    self?.categories = Array(categories).sorted()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadBestSellingProducts(completion: @escaping () -> Void) {
        Logger.info("Loading best selling products")
        
        productRepository.getAllProducts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionStatus in
                if case .failure(let error) = completionStatus {
                    Logger.error("Error loading best selling products: \(error)")
                    self?.errorMessage = "Failed to load best sellers: \(error.localizedDescription)"
                }
                completion()
            } receiveValue: { [weak self] products in
                // Sort products by sales count (highest first) and take top 10
                self?.bestSellingProducts = products
                    .sorted(by: { $0.salesCount > $1.salesCount })
                    .prefix(10)
                    .map { $0 }
                
                Logger.info("Loaded \(self?.bestSellingProducts.count ?? 0) best selling products")
            }
            .store(in: &cancellables)
    }
    
    // Helper function to compare creation dates
    private func compareCreationDates(_ date1: String, _ date2: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        guard let date1 = dateFormatter.date(from: date1),
              let date2 = dateFormatter.date(from: date2) else {
            return false
        }
        
        return date1 > date2 // Sort newest first
    }
    
    // Formatting helpers for prices
    func formattedPrice(_ price: Decimal) -> String {
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
    
    func discountedPrice(for product: Product) -> Decimal {
        let discount = product.price * Decimal(product.discountPercentage) / 100
        return (product.price - discount).rounded(2)
    }
    
    func formattedDiscountedPrice(for product: Product) -> String {
        let discountedPrice = discountedPrice(for: product)
        return currencyFormatter.string(from: discountedPrice as NSDecimalNumber) ?? "$\(discountedPrice)"
    }
}
