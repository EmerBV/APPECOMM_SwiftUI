//
//  CheckoutService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

protocol CheckoutServiceProtocol {
    func createOrder(userId: Int) -> AnyPublisher<Order, NetworkError>
    func getOrderById(orderId: Int) -> AnyPublisher<Order, NetworkError>
    func processPayment(orderId: Int, paymentRequest: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
}

final class CheckoutService: CheckoutServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func createOrder(userId: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = OrderEndpoints.createOrder(userId: userId)
        Logger.info("Creating order for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("Successfully created order: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to create order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getOrderById(orderId: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = OrderEndpoints.getOrderById(orderId: orderId)
        Logger.info("Fetching order \(orderId)")
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("Successfully fetched order: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to fetch order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func processPayment(orderId: Int, paymentRequest: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError> {
        let endpoint = PaymentEndpoints.createPaymentIntent(orderId: orderId, request: paymentRequest)
        Logger.info("Processing payment for order \(orderId)")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .map { response -> PaymentIntentResponse in
                Logger.info("Successfully created payment intent: \(response.data.paymentIntentId)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to process payment: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        let endpoint = PaymentEndpoints.confirmPayment(paymentIntentId: paymentIntentId)
        Logger.info("Confirming payment intent: \(paymentIntentId)")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentConfirmationResponse>.self, endpoint)
            .map { response -> PaymentConfirmationResponse in
                Logger.info("Payment confirmation: \(response.data.success)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to confirm payment: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
