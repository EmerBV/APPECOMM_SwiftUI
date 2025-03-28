//
//  PaymentService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

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
        Logger.info("Creating payment intent for order ID: \(orderId)")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .map { response -> PaymentIntentResponse in
                Logger.info("Payment intent created successfully: \(response.data.paymentIntentId)")
                return response.data
            }
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
