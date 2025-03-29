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

/// Cliente especializado para interactuar con la API de Stripe
class StripeAPIClient {
    private let networkDispatcher: NetworkDispatcherProtocol
    private var stripePublishableKey: String?
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    /// Configura la clave publicable de Stripe
    func configure(with publishableKey: String) {
        self.stripePublishableKey = publishableKey
        StripeAPI.defaultPublishableKey = publishableKey
        Logger.payment("Stripe configured with publishable key", level: .info)
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
            return Fail(error: NetworkError.unknown("Stripe not configured"))
                .eraseToAnyPublisher()
        }
        
        let endpoint = PaymentEndpoints.createPaymentIntent(orderId: orderId, request: paymentRequest)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    /// Confirma un PaymentIntent existente
    func confirmPaymentIntent(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        let endpoint = PaymentEndpoints.confirmPayment(paymentIntentId: paymentIntentId)
        
        return networkDispatcher.dispatch(ApiResponse<PaymentConfirmationResponse>.self, endpoint)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    /// Cancela un PaymentIntent
    func cancelPaymentIntent(paymentIntentId: String) -> AnyPublisher<Void, NetworkError> {
        let endpoint = PaymentEndpoints.cancelPayment(paymentIntentId: paymentIntentId)
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// Crea un método de pago con Stripe SDK
    func createPaymentMethod(withCard card: CreditCardDetails) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // Verificar que Stripe esté configurado
            guard self.stripePublishableKey != nil else {
                Logger.payment("Stripe not configured before creating payment method", level: .error)
                promise(.failure(PaymentError.notConfigured))
                return
            }
            
            // Verificar datos de la tarjeta
            if card.cardNumber.isEmpty || card.expiryDate.isEmpty || card.cvv.isEmpty {
                promise(.failure(PaymentError.invalidCardDetails))
                return
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
                promise(.failure(PaymentError.invalidExpiryDate))
                return
            }
            
            cardParams.cvc = card.cvv
            
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
                    promise(.failure(PaymentError.paymentMethodCreationFailed))
                    return
                }
                
                Logger.payment("Payment method created: \(paymentMethod.stripeId)", level: .info)
                promise(.success(paymentMethod.stripeId))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Presentar flujo de pago 3D Secure si es necesario
    func handlePaymentAuthentication(paymentIntentClientSecret: String, from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        
        STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: nil) { status, paymentIntent, error in
            switch status {
            case .succeeded:
                Logger.payment("Payment confirmation succeeded", level: .info)
                completion(true, nil)
            case .canceled:
                Logger.payment("Payment confirmation canceled by user", level: .info)
                completion(false, PaymentError.userCancelled)
            case .failed:
                let paymentError = error ?? PaymentError.unknown
                Logger.payment("Payment confirmation failed: \(paymentError.localizedDescription)", level: .error)
                completion(false, paymentError)
            @unknown default:
                Logger.payment("Unknown payment confirmation status", level: .error)
                completion(false, PaymentError.unknown)
            }
        }
    }
}

/// Errores específicos de pago
enum PaymentError: Error, LocalizedError {
    case notConfigured
    case invalidCardDetails
    case invalidExpiryDate
    case paymentMethodCreationFailed
    case paymentIntentCreationFailed
    case paymentConfirmationFailed
    case paymentAuthenticationRequired
    case insufficientFunds
    case cardDeclined
    case cardExpired
    case userCancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Payment system is not properly configured"
        case .invalidCardDetails:
            return "Invalid card details"
        case .invalidExpiryDate:
            return "Invalid expiry date format"
        case .paymentMethodCreationFailed:
            return "Failed to create payment method"
        case .paymentIntentCreationFailed:
            return "Failed to create payment intent"
        case .paymentConfirmationFailed:
            return "Payment confirmation failed"
        case .paymentAuthenticationRequired:
            return "Additional authentication required"
        case .insufficientFunds:
            return "Insufficient funds"
        case .cardDeclined:
            return "Card declined"
        case .cardExpired:
            return "Card expired"
        case .userCancelled:
            return "Payment cancelled by user"
        case .unknown:
            return "Unknown payment error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "Please try again later or contact support."
        case .invalidCardDetails:
            return "Check your card details and try again."
        case .invalidExpiryDate:
            return "Please enter the expiry date in MM/YY format."
        case .paymentMethodCreationFailed, .paymentIntentCreationFailed, .paymentConfirmationFailed:
            return "Please try again or use a different payment method."
        case .paymentAuthenticationRequired:
            return "Please complete the additional authentication steps required by your bank."
        case .insufficientFunds:
            return "Please use a different card or add funds to your account."
        case .cardDeclined:
            return "Your card was declined. Please use a different card or contact your bank."
        case .cardExpired:
            return "Your card has expired. Please use a different card."
        case .userCancelled:
            return "You cancelled the payment process."
        case .unknown:
            return "Please try again or contact customer support."
        }
    }
}
