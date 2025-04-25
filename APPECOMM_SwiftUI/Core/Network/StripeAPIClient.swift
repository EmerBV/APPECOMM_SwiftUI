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
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError>
    func createPaymentIntent(orderId: Int, paymentRequest: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    func confirmPaymentIntent(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
    func cancelPaymentIntent(paymentIntentId: String) -> AnyPublisher<Void, NetworkError>
    func createPaymentMethod(withCard cardDetails: CreditCardDetails) -> AnyPublisher<String, NetworkError>
    func createCustomer(userId: Int, email: String) -> AnyPublisher<StripeCustomer, NetworkError>
    func handlePaymentAuthentication(paymentIntentClientSecret: String, from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void)
    
}

//// Implementación del cliente API de Stripe para comunicación con el backend
final class StripeAPIClient: StripeAPIClientProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    /// Obtener configuración de Stripe desde el servidor
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError> {
        let endpoint = PaymentEndpoints.getStripeConfig
        Logger.payment("Getting Stripe configuration", level: .info)
        
        return networkDispatcher.dispatch(ApiResponse<StripeConfig>.self, endpoint)
            .map { response -> StripeConfig in
                Logger.payment("Successfully received Stripe configuration", level: .info)
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to get Stripe configuration: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Crea un PaymentIntent para procesar un pago
    func createPaymentIntent(orderId: Int, paymentRequest: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError> {
        let endpoint = PaymentEndpoints.createPaymentIntent(orderId: orderId, request: paymentRequest)
        Logger.payment("Creating payment intent for order \(orderId)", level: .info)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .map { response -> PaymentIntentResponse in
                Logger.payment("Successfully created payment intent: \(response.data.paymentIntentId)", level: .info)
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to create payment intent: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Confirma un PaymentIntent existente
    func confirmPaymentIntent(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        let endpoint = PaymentEndpoints.confirmPaymentIntent(
            paymentIntentId: paymentIntentId,
            paymentMethodId: paymentMethodId
        )
        Logger.payment("Confirming payment intent: \(paymentIntentId)", level: .info)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentConfirmationResponse>.self, endpoint)
            .map { response -> PaymentConfirmationResponse in
                Logger.payment("Payment confirmation response: \(response.data.success)", level: .info)
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to confirm payment: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Cancela un PaymentIntent
    func cancelPaymentIntent(paymentIntentId: String) -> AnyPublisher<Void, NetworkError> {
        let endpoint = PaymentEndpoints.cancelPaymentIntent(paymentIntentId: paymentIntentId)
        Logger.payment("Cancelling payment intent: \(paymentIntentId)", level: .info)
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.payment("Successfully cancelled payment intent", level: .info)
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to cancel payment: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Crea un método de pago con Stripe SDK
    func createPaymentMethod(withCard cardDetails: CreditCardDetails) -> AnyPublisher<String, NetworkError> {
        let endpoint = PaymentEndpoints.createPaymentMethod(cardDetails: cardDetails)
        Logger.payment("Creating payment method with card", level: .info)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentMethodResponse>.self, endpoint)
            .map { response -> String in
                Logger.payment("Successfully created payment method: \(response.data.id)", level: .info)
                return response.data.id
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to create payment method: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
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
        
        STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: viewController as STPAuthenticationContext) { status, paymentIntent, error in
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
        let endpoint = PaymentEndpoints.createCustomer(userId: userId, email: email)
        Logger.payment("Creating Stripe customer for user \(userId)", level: .info)
        
        return networkDispatcher.dispatch(ApiResponse<StripeCustomer>.self, endpoint)
            .map { response -> StripeCustomer in
                Logger.payment("Successfully created Stripe customer: \(response.data.id)", level: .info)
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Failed to create Stripe customer: \(error)", level: .error)
                }
            })
            .eraseToAnyPublisher()
    }
}

struct PaymentMethodResponse: Codable {
    let id: String
    let type: String
}
