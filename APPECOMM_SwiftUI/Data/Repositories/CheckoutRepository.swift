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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let orderDateString = dateFormatter.string(from: Date())
        
        let order = Order(
            id: 0, // El ID será asignado por el servidor
            userId: userId,
            orderDate: orderDateString,
            totalAmount: 0.0,
            status: "pending",
            items: []
        )
        
        return checkoutService.createOrder(order)
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
        
        guard let paymentMethodId = paymentMethodId else {
            return Fail(error: NSError(domain: "CheckoutRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Payment method ID is required"]))
                .eraseToAnyPublisher()
        }
        
        let paymentRequest = PaymentRequest(paymentMethodId: paymentMethodId)
        
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
        
        return paymentService.confirmPayment(paymentIntentId: paymentIntentId, paymentMethodId: "")
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
        
        return checkoutService.getOrder(id: orderId)
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
