//
//  StripeAPIClient.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 29/3/25.
//

import Foundation
import Combine
import Stripe
import UIKit

protocol StripeAPIClientProtocol {
    func configure(with publicKey: String)
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError>
    func createPaymentIntent(orderId: Int, paymentRequest: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    func confirmPaymentIntent(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
    func cancelPaymentIntent(paymentIntentId: String) -> AnyPublisher<Void, NetworkError>
    func createPaymentMethod(withCard card: CreditCardDetails) -> AnyPublisher<String, Error>
    func handlePaymentAuthentication(paymentIntentClientSecret: String, from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void)
    func createCustomer(userId: Int, email: String) -> AnyPublisher<StripeCustomer, NetworkError>
}

/// Cliente especializado para interactuar con la API de Stripe
class StripeAPIClient: StripeAPIClientProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    private var stripePublishableKey: String?
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    /// Configura la clave publicable de Stripe
    func configure(with publicKey: String) {
        self.stripePublishableKey = publicKey
        StripeAPI.defaultPublishableKey = publicKey
        Logger.payment("Stripe configured with publishable key: \(publicKey)", level: .info)
    }
    
    /// Obtener configuración de Stripe desde el servidor
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError> {
        let endpoint = PaymentEndpoints.getStripeConfig
        
        return networkDispatcher.dispatch(ApiResponse<StripeConfig>.self, endpoint)
            .handleEvents(receiveOutput: { [weak self] response in
                // Configurar Stripe SDK con la clave publicable
                self?.configure(with: response.data.publicKey)
            })
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    /// Crea un PaymentIntent para procesar un pago
    func createPaymentIntent(orderId: Int, paymentRequest: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError> {
        // Verificar que Stripe esté configurado
        guard stripePublishableKey != nil else {
            Logger.payment("Stripe not configured before creating payment intent", level: .error)
            return Fail(error: NetworkError.unknown(NSError(
                domain: "com.appecomm.StripeAPIClient",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Stripe not configured"]
            )))
            .eraseToAnyPublisher()
        }
        
        let endpoint = PaymentEndpoints.createPaymentIntent(orderId: orderId, request: paymentRequest)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .map { $0.data }
            .handleEvents(receiveOutput: { response in
                Logger.payment("PaymentIntent created: \(response.paymentIntentId)", level: .info)
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to create PaymentIntent: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Confirma un PaymentIntent existente
    func confirmPaymentIntent(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        // Crear parámetros para confirmación
        let parameters: [String: Any] = [
            "paymentMethodId": paymentMethodId
        ]
        
        let endpoint = PaymentEndpoints.confirmPayment(paymentIntentId: paymentIntentId)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentConfirmationResponse>.self, endpoint)
            .map { $0.data }
            .handleEvents(receiveOutput: { response in
                Logger.payment("Payment confirmation: \(response.success)", level: .info)
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Payment confirmation failed: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Cancela un PaymentIntent
    func cancelPaymentIntent(paymentIntentId: String) -> AnyPublisher<Void, NetworkError> {
        let endpoint = PaymentEndpoints.cancelPayment(paymentIntentId: paymentIntentId)
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ in () }
            .handleEvents(receiveOutput: { _ in
                Logger.payment("Payment intent canceled: \(paymentIntentId)", level: .info)
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to cancel payment: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Crea un método de pago con Stripe SDK
    func createPaymentMethod(withCard card: CreditCardDetails) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // Verificar que Stripe esté configurado
            guard self.stripePublishableKey != nil else {
                Logger.payment("Stripe not configured before creating payment method", level: .error)
                promise(.failure(NSError(
                    domain: "com.appecomm.StripeAPIClient",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Stripe not configured"]
                )))
                return
            }
            
            // Validar datos de la tarjeta
            do {
                let cardParams = try self.validateAndCreateCardParams(card)
                
                // Detalles de facturación
                let billingDetails = STPPaymentMethodBillingDetails()
                billingDetails.name = card.cardholderName
                
                // Crear parámetros para el método de pago
                let paymentMethodParams = STPPaymentMethodParams(
                    card: cardParams,
                    billingDetails: billingDetails,
                    metadata: nil
                )
                
                // Crear el método de pago con Stripe
                STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                    if let error = error {
                        Logger.payment("Error creating payment method: \(error.localizedDescription)", level: .error)
                        promise(.failure(error))
                        return
                    }
                    
                    guard let paymentMethod = paymentMethod else {
                        promise(.failure(NSError(
                            domain: "com.appecomm.StripeAPIClient",
                            code: 1004,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create payment method"]
                        )))
                        return
                    }
                    
                    Logger.payment("Payment method created: \(paymentMethod.stripeId)", level: .info)
                    promise(.success(paymentMethod.stripeId))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Validar y crear parámetros de tarjeta de crédito
    private func validateAndCreateCardParams(_ card: CreditCardDetails) throws -> STPPaymentMethodCardParams {
        // Verificar datos de la tarjeta
        if card.cardNumber.isEmpty || card.expiryDate.isEmpty || card.cvv.isEmpty {
            throw NSError(
                domain: "com.appecomm.StripeAPIClient",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Invalid card details"]
            )
        }
        
        // Crear parámetros para la tarjeta
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = card.cardNumber.replacingOccurrences(of: " ", with: "")
        
        // Parsear fecha de expiración
        let expiryComponents = card.expiryDate.split(separator: "/")
        if expiryComponents.count == 2,
           let month = UInt(expiryComponents[0]),
           let year = UInt("20" + String(expiryComponents[1])) {
            cardParams.expMonth = NSNumber(value: month)
            cardParams.expYear = NSNumber(value: year)
        } else {
            throw NSError(
                domain: "com.appecomm.StripeAPIClient",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Invalid expiry date"]
            )
        }
        
        cardParams.cvc = card.cvv
        return cardParams
    }
    
    /// Presentar flujo de pago 3D Secure si es necesario
    func handlePaymentAuthentication(paymentIntentClientSecret: String, from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        
        STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: viewController) { status, paymentIntent, error in
            switch status {
            case .succeeded:
                Logger.payment("Payment confirmation succeeded", level: .info)
                completion(true, nil)
            case .canceled:
                Logger.payment("Payment confirmation canceled by user", level: .info)
                completion(false, NSError(
                    domain: "com.appecomm.StripeAPIClient",
                    code: 1011,
                    userInfo: [NSLocalizedDescriptionKey: "User cancelled the payment"]
                ))
            case .failed:
                let paymentError = error ?? NSError(
                    domain: "com.appecomm.StripeAPIClient",
                    code: 1000,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown payment error"]
                )
                Logger.payment("Payment confirmation failed: \(paymentError.localizedDescription)", level: .error)
                completion(false, paymentError)
            @unknown default:
                Logger.payment("Unknown payment confirmation status", level: .error)
                completion(false, NSError(
                    domain: "com.appecomm.StripeAPIClient",
                    code: 1000,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown error"]
                ))
            }
        }
    }
    
    /// Crea un cliente en Stripe para el usuario
    func createCustomer(userId: Int, email: String) -> AnyPublisher<StripeCustomer, NetworkError> {
        let parameters: [String: Any] = [
            "userId": userId,
            "email": email
        ]
        
        // Endpoint para crear cliente en Stripe (debe ser implementado en tu API)
        let endpoint = PaymentEndpoints.createCustomer(parameters: parameters)
        
        return networkDispatcher.dispatch(ApiResponse<StripeCustomer>.self, endpoint)
            .map { $0.data }
            .handleEvents(receiveOutput: { customer in
                Logger.payment("Stripe customer created: \(customer.id)", level: .info)
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to create Stripe customer: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
}

struct StripeCustomer: Codable {
    let id: String
    let object: String
    let email: String?
    let created: Int
}
