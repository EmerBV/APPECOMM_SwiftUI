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
    
    func createOrder(userId: Int) -> AnyPublisher<Order, Error>
    func processPayment(orderId: Int, paymentMethodId: String?) -> AnyPublisher<PaymentIntentResponse, Error>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<Bool, Error>
    func getOrderDetails(orderId: Int) -> AnyPublisher<Order, Error>
    func resetCheckoutState()
    
    func debugCheckoutState()
}

final class CheckoutRepository: CheckoutRepositoryProtocol {
    var checkoutState: CurrentValueSubject<CheckoutState, Never> = CurrentValueSubject(.initial)
    var paymentState: CurrentValueSubject<PaymentState, Never> = CurrentValueSubject(.initial)
    
    private let checkoutService: CheckoutServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(checkoutService: CheckoutServiceProtocol, paymentService: PaymentServiceProtocol) {
        self.checkoutService = checkoutService
        self.paymentService = paymentService
    }
    
    func createOrder(userId: Int) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Creating order for user \(userId)")
        checkoutState.send(.processing)
        
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
    
    func processPayment(orderId: Int, paymentMethodId: String?) -> AnyPublisher<PaymentIntentResponse, Error> {
        Logger.info("CheckoutRepository: Processing payment for order \(orderId)")
        paymentState.send(.preparing)
        
        guard let paymentMethodId = paymentMethodId else {
            let error = NSError(domain: "CheckoutRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Payment method ID is required"])
            paymentState.send(.failed(error.localizedDescription))
            return Fail(error: error).eraseToAnyPublisher()
        }
        
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
        
        // Primero convertimos NetworkError a Error
        return paymentService.confirmPayment(paymentIntentId: paymentIntentId, paymentMethodId: "")
            .mapError { $0 as Error } // Convertir NetworkError a Error
            .flatMap { [weak self] response -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "CheckoutRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self está nulo"]))
                        .eraseToAnyPublisher()
                }
                
                Logger.info("CheckoutRepository: Payment confirmation: \(response.success)")
                
                if response.success {
                    // Si el pago fue exitoso, obtenemos los detalles del pedido
                    if let orderId = self.getOrderIdFromPaymentIntent(paymentIntentId) {
                        return self.getOrderDetails(orderId: orderId)
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
                        
                        // El pago fue exitoso pero no tenemos el ID del pedido
                        self.paymentState.send(.completed(Order(
                            id: 0,
                            userId: 0,
                            orderDate: "",
                            totalAmount: 0.0,
                            status: "paid",
                            items: []
                        )))
                        
                        return result
                    }
                } else {
                    // Si el pago falló
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
        // En una implementación real, deberíamos tener una forma de obtener el ID del pedido
        // a partir del ID del intent de pago, quizás almacenándolo en UserDefaults o en memoria.
        // Para esta implementación, lo obtendremos de PaymentState si está disponible
        
        if case .ready(let clientSecret) = paymentState.value,
           let storedOrderId = extractOrderIdFromClientSecret(clientSecret) {
            return storedOrderId
        }
        
        return nil
    }
    
    private func extractOrderIdFromClientSecret(_ clientSecret: String) -> Int? {
        // Este es un método ficticio para extraer el ID del pedido del client secret
        // En una implementación real, el servidor debería proporcionar esta información
        // o almacenarla en algún lugar al crear el payment intent
        return nil
    }
    
    func getOrderDetails(orderId: Int) -> AnyPublisher<Order, Error> {
        Logger.info("CheckoutRepository: Fetching order details for order \(orderId)")
        
        return checkoutService.getOrder(id: orderId)
            .handleEvents(receiveOutput: { order in
                Logger.info("CheckoutRepository: Order details fetched successfully: \(order.id)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutRepository: Failed to fetch order details: \(error)")
                }
            })
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
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
    }
}
