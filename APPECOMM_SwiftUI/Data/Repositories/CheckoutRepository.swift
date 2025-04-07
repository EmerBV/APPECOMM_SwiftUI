//
//  CheckoutRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

protocol CheckoutRepositoryProtocol {
    var checkoutState: CurrentValueSubject<CheckoutState, Never> { get }
    var paymentState: CurrentValueSubject<PaymentState, Never> { get }
    var orderListState: CurrentValueSubject<OrderListState, Never> { get }
    var orderDetailState: CurrentValueSubject<OrderDetailState, Never> { get }
    
    // Order creation and management
    func createOrder(userId: Int, shippingDetailsId: Int) -> AnyPublisher<Order, Error>
    func getOrderById(id: Int) -> AnyPublisher<Order, Error>
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], Error>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error>
    func refreshOrders(userId: Int) -> AnyPublisher<[Order], Error>
    
    // Payment processing
    func processPayment(orderId: Int, paymentMethodId: String?) -> AnyPublisher<PaymentIntentResponse, Error>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<Bool, Error>
    
    // State management
    func resetCheckoutState()
    func debugCheckoutState()
}

final class CheckoutRepository: CheckoutRepositoryProtocol {
    // MARK: - Published States
    
    var checkoutState: CurrentValueSubject<CheckoutState, Never> = CurrentValueSubject(.initial)
    var paymentState: CurrentValueSubject<PaymentState, Never> = CurrentValueSubject(.initial)
    var orderListState: CurrentValueSubject<OrderListState, Never> = CurrentValueSubject(.initial)
    var orderDetailState: CurrentValueSubject<OrderDetailState, Never> = CurrentValueSubject(.initial)
    
    // MARK: - Dependencies
    
    private let checkoutService: CheckoutServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(checkoutService: CheckoutServiceProtocol, paymentService: PaymentServiceProtocol) {
        self.checkoutService = checkoutService
        self.paymentService = paymentService
    }
    
    // MARK: - Order Creation and Management
    
    func createOrder(userId: Int, shippingDetailsId: Int) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Creating order for user \(userId) with shipping details ID \(shippingDetailsId)")
        checkoutState.send(.processing)
        
        return checkoutService.createOrder(userId: userId, shippingDetailsId: shippingDetailsId)
            .handleEvents(receiveOutput: { [weak self] order in
                Logger.info("CheckoutRepository: Order created successfully: \(order.id)")
                self?.checkoutState.send(.orderSummary)
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to create order: \(error)")
                    self?.checkoutState.send(.failed(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getOrderById(id: Int) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Getting order details for ID: \(id)")
        orderDetailState.send(.loading)
        
        return checkoutService.getOrder(id: id)
            .handleEvents(receiveOutput: { [weak self] order in
                Logger.info("CheckoutRepository: Received order details for ID: \(order.id)")
                self?.orderDetailState.send(.loaded(order))
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to get order details: \(error)")
                    self?.orderDetailState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], Error> {
        Logger.info("CheckoutRepository: Getting orders for user: \(userId)")
        orderListState.send(.loading)
        
        return checkoutService.getUserOrders(userId: userId)
            .handleEvents(receiveOutput: { [weak self] orders in
                Logger.info("CheckoutRepository: Received \(orders.count) orders")
                if orders.isEmpty {
                    self?.orderListState.send(.empty)
                } else {
                    self?.orderListState.send(.loaded(orders))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to get orders: \(error)")
                    self?.orderListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Updating order status - ID: \(id), Status: \(status)")
        orderDetailState.send(.loading)
        
        return checkoutService.updateOrderStatus(id: id, status: status)
            .handleEvents(receiveOutput: { [weak self] order in
                Logger.info("CheckoutRepository: Order status updated successfully: \(order.id)")
                self?.orderDetailState.send(.loaded(order))
                
                // Refresh order list state if loaded
                if case .loaded(let orders) = self?.orderListState.value {
                    var updatedOrders = orders
                    if let index = updatedOrders.firstIndex(where: { $0.id == order.id }) {
                        updatedOrders[index] = order
                        self?.orderListState.send(.loaded(updatedOrders))
                    }
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to update order status: \(error)")
                    self?.orderDetailState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func refreshOrders(userId: Int) -> AnyPublisher<[Order], Error> {
        Logger.info("CheckoutRepository: Refreshing orders for user: \(userId)")
        
        return checkoutService.getUserOrders(userId: userId)
            .handleEvents(receiveOutput: { [weak self] orders in
                Logger.info("CheckoutRepository: Orders refreshed: \(orders.count) orders")
                if orders.isEmpty {
                    self?.orderListState.send(.empty)
                } else {
                    self?.orderListState.send(.loaded(orders))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to refresh orders: \(error)")
                    self?.orderListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Payment Processing
    
    func processPayment(orderId: Int, paymentMethodId: String?) -> AnyPublisher<PaymentIntentResponse, Error> {
        Logger.info("CheckoutRepository: Processing payment for order \(orderId)")
        paymentState.send(.preparing)
        
        let paymentRequest = PaymentRequest(paymentMethodId: paymentMethodId)
        
        return paymentService.createPaymentIntent(orderId: orderId, request: paymentRequest)
            .handleEvents(receiveOutput: { [weak self] response in
                Logger.info("CheckoutRepository: Payment intent created: \(response.paymentIntentId)")
                self?.paymentState.send(.ready(clientSecret: response.clientSecret))
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to create payment intent: \(error)")
                    self?.paymentState.send(.failed(error.localizedDescription))
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<Bool, Error> {
        Logger.info("CheckoutRepository: Confirming payment \(paymentIntentId)")
        paymentState.send(.processing)
        
        // First convert NetworkError to Error
        return paymentService.confirmPayment(paymentIntentId: paymentIntentId, paymentMethodId: "")
            .mapError { $0 as Error }
            .flatMap { [weak self] response -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "CheckoutRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"]))
                        .eraseToAnyPublisher()
                }
                
                Logger.info("CheckoutRepository: Payment confirmation: \(response.success)")
                
                if response.success {
                    // If payment was successful, get order details
                    if let orderId = self.getOrderIdFromPaymentIntent(paymentIntentId) {
                        return self.getOrderById(id: orderId)
                            .map { order -> Bool in
                                self.paymentState.send(.completed(order))
                                self.checkoutState.send(.completed(order))
                                return true
                            }
                            .eraseToAnyPublisher()
                    } else {
                        let result = Just(true)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                        
                        // Payment was successful but no order ID
                        self.paymentState.send(.completed(Order(
                            id: 0,
                            userId: 0,
                            orderDate: "",
                            totalAmount: 0.0,
                            status: "paid",
                            items: [],
                            shippingDetailsId: nil,
                            paymentMethod: nil,
                            paymentIntentId: nil
                        )))
                        
                        return result
                    }
                } else {
                    // If payment failed
                    let error = NSError(domain: "CheckoutRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Payment confirmation failed"])
                    self.paymentState.send(.failed(error.localizedDescription))
                    self.checkoutState.send(.failed(error.localizedDescription))
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to confirm payment: \(error)")
                    self?.paymentState.send(.failed(error.localizedDescription))
                    self?.checkoutState.send(.failed(error.localizedDescription))
                }
            })
            .eraseToAnyPublisher()
    }
    
    private func getOrderIdFromPaymentIntent(_ paymentIntentId: String) -> Int? {
        // In a real implementation, we should have a way to get the order ID
        // from the payment intent ID, perhaps storing it in UserDefaults or in memory.
        // For this implementation, we'll try to get it from PaymentState if available
        
        if case .ready(let clientSecret) = paymentState.value,
           let storedOrderId = extractOrderIdFromClientSecret(clientSecret) {
            return storedOrderId
        }
        
        return nil
    }
    
    private func extractOrderIdFromClientSecret(_ clientSecret: String) -> Int? {
        // This is a fictitious method to extract the order ID from client secret
        // In a real implementation, the server should provide this information
        // or store it somewhere when creating the payment intent
        return nil
    }
    
    // MARK: - State Management
    
    func resetCheckoutState() {
        checkoutState.send(.initial)
        paymentState.send(.initial)
    }
    
    func debugCheckoutState() {
        Logger.debug("Current checkout state: \(checkoutState.value)")
        Logger.debug("Current payment state: \(paymentState.value)")
        
        if case .completed(let order) = checkoutState.value {
            Logger.debug("Completed order: ID=\(order.id), Status=\(order.status), Total=\(order.totalAmount)")
        }
        
        if case .ready(let clientSecret) = paymentState.value {
            Logger.debug("Payment ready with client secret: \(clientSecret)")
        }
        
        Logger.debug("Current order list state: \(orderListState.value)")
        Logger.debug("Current order detail state: \(orderDetailState.value)")
    }
}
