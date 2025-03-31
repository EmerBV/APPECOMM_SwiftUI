//
//  PaymentSheetViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import Combine
import SwiftUI
import Stripe
import StripePaymentSheet

/// ViewModel específico para manejar el flujo de pago con PaymentSheet de Stripe
class PaymentSheetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: String?
    @Published var paymentStatus: PaymentStatus = .idle
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var clientSecret: String?
    
    // MARK: - Private Properties
    private let paymentService: PaymentServiceProtocol
    private let orderId: Int
    private let amount: Decimal
    private let email: String?
    private var paymentIntentId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    
    enum PaymentStatus {
        case idle
        case loading
        case ready
        case processing
        case completed
        case failed(String)
    }
    
    // MARK: - Initialization
    
    init(paymentService: PaymentServiceProtocol, orderId: Int, amount: Decimal, email: String? = nil) {
        self.paymentService = paymentService
        self.orderId = orderId
        self.amount = amount
        self.email = email
    }
    
    // MARK: - Public Methods
    
    /// Prepara el PaymentSheet con la configuración necesaria
    func preparePaymentSheet() {
        guard paymentSheet == nil else { return }
        
        isLoading = true
        paymentStatus = .loading
        
        // 1. Primero aseguramos que tenemos la configuración de Stripe
        paymentService.getStripeConfig()
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<PaymentCheckout, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "PaymentSheetViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                        .eraseToAnyPublisher()
                }
                
                // 2. Preparar el checkout con el Payment Intent
                return self.paymentService.prepareCheckout(
                    orderId: self.orderId,
                    amount: self.amount,
                    email: self.email
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.error = error.localizedDescription
                    self.paymentStatus = .failed(error.localizedDescription)
                    Logger.payment("Failed to prepare payment: \(error)", level: .error)
                }
            } receiveValue: { [weak self] checkout in
                guard let self = self else { return }
                
                self.clientSecret = checkout.clientSecret
                self.paymentIntentId = checkout.paymentIntentId
                
                // 3. Configurar PaymentSheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "APPECOMM"
                if let email = self.email {
                    configuration.defaultBillingDetails.email = email
                }
                
                // Configurar cliente si está disponible
                if let customerId = checkout.customerId, let ephemeralKey = checkout.ephemeralKey {
                    configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
                }
                
                // Crear PaymentSheet
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: checkout.clientSecret,
                    configuration: configuration
                )
                
                self.isLoading = false
                self.paymentStatus = .ready
                Logger.payment("Payment sheet ready with client secret", level: .info)
            }
            .store(in: &cancellables)
    }
    
    /// Maneja el resultado del pago
    func handlePaymentResult(_ result: PaymentSheetResult) {
        self.paymentResult = result
        
        switch result {
        case .completed:
            Logger.payment("Payment completed successfully", level: .info)
            paymentStatus = .completed
            // Notificar éxito al sistema
            NotificationCenter.default.post(
                name: Notification.Name("PaymentCompleted"),
                object: nil,
                userInfo: ["orderId": orderId, "paymentIntentId": paymentIntentId ?? ""]
            )
            
        case .canceled:
            Logger.payment("Payment canceled by user", level: .info)
            paymentStatus = .idle
            if let paymentIntentId = paymentIntentId {
                // Cancelar el pago en el servidor
                cancelPayment(paymentIntentId: paymentIntentId)
            }
            
        case .failed(let error):
            Logger.payment("Payment failed: \(error)", level: .error)
            paymentStatus = .failed(error.localizedDescription)
            self.error = error.localizedDescription
        }
    }
    
    /// Reinicia el estado del pago
    func reset() {
        paymentStatus = .idle
        error = nil
        paymentResult = nil
        // No reiniciamos paymentSheet para evitar tener que crearlo de nuevo
    }
    
    // MARK: - Private Methods
    
    /// Cancela un PaymentIntent
    private func cancelPayment(paymentIntentId: String) {
        paymentService.cancelPayment(paymentIntentId: paymentIntentId)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to cancel payment: \(error)", level: .error)
                }
            } receiveValue: { _ in
                Logger.payment("Payment intent canceled: \(paymentIntentId)", level: .info)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    // Expone el monto para la vista
    var amountFormatted: String {
        return amount.toCurrentLocalePrice
    }
}
