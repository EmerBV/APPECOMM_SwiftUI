//
//  PaymentService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

protocol PaymentServiceProtocol {
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError>
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError>
}

struct PaymentRequest: Codable {
    let orderId: Int
    let paymentMethodId: String?
    let currency: String
    let receiptEmail: String?
    let description: String?
    
    // Asegurarse de que se codifican correctamente los campos opcionales
    enum CodingKeys: String, CodingKey {
        case orderId, paymentMethodId, currency, receiptEmail, description
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(orderId, forKey: .orderId)
        try container.encodeIfPresent(paymentMethodId, forKey: .paymentMethodId)
        try container.encode(currency, forKey: .currency)
        try container.encodeIfPresent(receiptEmail, forKey: .receiptEmail)
        try container.encodeIfPresent(description, forKey: .description)
    }
}

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
}

struct PaymentConfirmationResponse: Codable {
    let status: String
    let success: Bool
    let message: String
}

struct StripeConfig: Codable {
    let publicKey: String
    let currency: String
    let locale: String
}

final class PaymentService: PaymentServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError> {
        let endpoint = PaymentEndpoints.getStripeConfig
        Logger.info("Getting Stripe configuration")
        
        return networkDispatcher.dispatch(ApiResponse<StripeConfig>.self, endpoint)
            .map { response -> StripeConfig in
                Logger.info("Stripe configuration retrieved successfully")
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError> {
        let endpoint = PaymentEndpoints.createPaymentIntent(orderId: orderId, request: request)
        Logger.info("Creating payment intent for order ID: \(orderId), paymentMethodId: \(request.paymentMethodId ?? "none")")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .handleEvents(receiveSubscription: { _ in
                Logger.debug("Payment intent subscription started")
            }, receiveOutput: { response in
                Logger.info("Payment intent created successfully: \(response.data.paymentIntentId)")
            }, receiveCompletion: { completion in
                switch completion {
                case .finished:
                    Logger.info("Payment intent request completed successfully")
                case .failure(let error):
                    Logger.error("Failed to create payment intent: \(error)")
                }
            }, receiveCancel: {
                Logger.debug("Payment intent request cancelled")
            }, receiveRequest: { _ in
                Logger.debug("Payment intent request received")
            })
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        let endpoint = PaymentEndpoints.confirmPayment(paymentIntentId: paymentIntentId)
        Logger.info("Confirming payment intent: \(paymentIntentId)")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentConfirmationResponse>.self, endpoint)
            .map { response -> PaymentConfirmationResponse in
                Logger.info("Payment confirmed: \(response.data.success)")
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError> {
        let endpoint = PaymentEndpoints.cancelPayment(paymentIntentId: paymentIntentId)
        Logger.info("Cancelling payment intent: \(paymentIntentId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("Payment cancelled successfully")
                return ()
            }
            .eraseToAnyPublisher()
    }
}
