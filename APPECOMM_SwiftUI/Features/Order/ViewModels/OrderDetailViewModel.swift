//
//  OrderDetailViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import Combine

class OrderDetailViewModel: ObservableObject {
    @Published var order: Order?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let checkoutService: CheckoutServiceProtocol
    
    init() {
        // Get dependencies from DI container
        self.checkoutService = DependencyInjector.shared.resolve(CheckoutServiceProtocol.self)
    }
    
    func loadOrderDetails(orderId: Int) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        checkoutService.getOrder(id: orderId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Failed to load order details: \(error)")
                }
            } receiveValue: { [weak self] order in
                self?.order = order
                Logger.info("Successfully loaded order details for order #\(order.id)")
            }
            .store(in: &cancellables)
    }
    
    func contactSupport() {
        // In a real app, this would open a support chat or email
        showAlert = true
        alertMessage = "Support request sent. Our team will contact you shortly."
        
        // Simulate API call
        Logger.info("User requested support for order #\(order?.id ?? 0)")
    }
    
    func reorder() {
        // In a real app, this would add the same items to the cart
        showAlert = true
        alertMessage = "Items have been added to your cart."
        
        // Simulate API call
        Logger.info("User requested to reorder items from order #\(order?.id ?? 0)")
        
        // Notify the cart view to refresh
        NotificationCenter.default.post(
            name: Notification.Name("RefreshCart"),
            object: nil
        )
    }
}
