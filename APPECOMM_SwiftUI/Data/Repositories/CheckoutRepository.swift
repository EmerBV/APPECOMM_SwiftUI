//
//  CheckoutRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

protocol CheckoutRepositoryProtocol {
    func createOrder(userId: Int) -> AnyPublisher<Order, Error>
    func processPayment(orderId: Int, paymentMethodId: String?) -> AnyPublisher<PaymentIntentResponse, Error>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<Bool, Error>
    func getOrderDetails(orderId: Int) -> AnyPublisher<Order, Error>
}

final class CheckoutRepository: CheckoutRepositoryProtocol {
    private let checkoutService: CheckoutServiceProtocol
    private let paymentService: PaymentServiceProtocol
    
    init(checkoutService: CheckoutServiceProtocol, paymentService: PaymentServiceProtocol) {
        self.checkoutService = checkoutService
        self.paymentService = paymentService
    }
    
    func createOrder(userId: Int) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Creating order for user \(userId)")
        
        return checkoutService.createOrder(userId: userId)
            .mapError { $0 as Error }
            .handleEvents(receiveOutput: { order in
                Logger.info("CheckoutRepository: Order created successfully: \(order.id)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to create order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func processPayment(orderId: Int, paymentMethodId: String?) -> AnyPublisher<PaymentIntentResponse, Error> {
        Logger.info("CheckoutRepository: Processing payment for order \(orderId)")
        
        let paymentRequest = PaymentRequest(
            orderId: orderId,
            paymentMethodId: paymentMethodId,
            currency: "usd", // Default currency
            receiptEmail: nil,
            description: nil
        )
        
        return paymentService.createPaymentIntent(orderId: orderId, request: paymentRequest)
            .mapError { $0 as Error }
            .handleEvents(receiveOutput: { response in
                Logger.info("CheckoutRepository: Payment intent created: \(response.paymentIntentId)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to create payment intent: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<Bool, Error> {
        Logger.info("CheckoutRepository: Confirming payment \(paymentIntentId)")
        
        return paymentService.confirmPayment(paymentIntentId: paymentIntentId)
            .map { response -> Bool in
                Logger.info("CheckoutRepository: Payment confirmation: \(response.success)")
                return response.success
            }
            .mapError { $0 as Error }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to confirm payment: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getOrderDetails(orderId: Int) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Fetching order details for order \(orderId)")
        
        return checkoutService.getOrderById(orderId: orderId)
            .mapError { $0 as Error }
            .handleEvents(receiveOutput: { order in
                Logger.info("CheckoutRepository: Order details fetched successfully: \(order.id)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to fetch order details: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
