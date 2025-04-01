//
//  OrdersViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

import Foundation
import Combine

class OrdersViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingOrders: [OrderSummary] = []
    @Published var completedOrders: [OrderSummary] = []
    
    private let authRepository: AuthRepositoryProtocol
    private let paymentService: PaymentServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authRepository: AuthRepositoryProtocol,
        paymentService: PaymentServiceProtocol
    ) {
        self.authRepository = authRepository
        self.paymentService = paymentService
        
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case let .loggedIn(user) = state {
                    self?.user = user
                    self?.separateOrders(user.orders)
                } else {
                    self?.user = nil
                    self?.pendingOrders = []
                    self?.completedOrders = []
                }
            }
            .store(in: &cancellables)
    }
    
    func loadOrders() {
        isLoading = true
        errorMessage = nil
        
        authRepository.checkAuthStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                self?.user = user
                self?.separateOrders(user?.orders)
            }
            .store(in: &cancellables)
    }
    
    private func separateOrders(_ orders: [OrderSummary]?) {
        guard let orders = orders else {
            pendingOrders = []
            completedOrders = []
            return
        }
        
        pendingOrders = orders.filter { order in
            let status = order.status.lowercased()
            return status == "pending" || status == "pending_payment"
        }
        
        completedOrders = orders.filter { order in
            let status = order.status.lowercased()
            return status != "pending" && status != "pending_payment"
        }
    }
    
    /*
     func resumePayment(for order: Order) {
     // Crear y mostrar un PaymentSheetView para esta orden
     let paymentSheetVM = PaymentSheetViewModel(
     paymentService: paymentService,
     orderId: order.id,
     amount: order.totalAmount,
     email: nil
     )
     
     // Usar la navegación o sheet para mostrar la vista de pago
     // Esto depende de la estructura de navegación de la app
     // En un caso real, probablemente usarías un coordinador o router
     
     // Ejemplo usando NotificationCenter para simplificar
     NotificationCenter.default.post(
     name: Notification.Name("ResumePaymentForOrder"),
     object: nil,
     userInfo: ["viewModel": paymentSheetVM]
     )
     }
     */
}
