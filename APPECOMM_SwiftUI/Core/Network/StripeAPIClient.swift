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
            return Fail(error: NetworkError.unknown(NSError(
                domain: "com.emerbv.APPECOMM-SwiftUI.StripeAPIClient",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Stripe not configured"]
            )))
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
    
    class SwiftUIAuthenticationContext: NSObject, STPAuthenticationContext {
        var presentingViewController: UIViewController {
            // Obtener el UIViewController principal desde la escena SwiftUI
            return UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
        }
        
        func authenticationPresentingViewController() -> UIViewController {
            return presentingViewController
        }
    }
    
    /// Presentar flujo de pago 3D Secure si es necesario
    func handlePaymentAuthentication(paymentIntentClientSecret: String, from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        
        let authContext = SwiftUIAuthenticationContext()
        
        STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: authContext) { status, paymentIntent, error in
            switch status {
            case .succeeded:
                Logger.payment("Payment confirmation succeeded", level: .info)
                completion(true, nil)
            case .canceled:
                Logger.payment("Payment confirmation canceled by user", level: .info)
                completion(false, NSError(
                    domain: "com.emerbv.APPECOMM-SwiftUI.PaymentError",
                    code: PaymentError.userCancelled.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: PaymentError.userCancelled.errorDescription ?? "User cancelled"]
                ))
            case .failed:
                let paymentError = error ?? NSError(
                    domain: "com.emerbv.APPECOMM-SwiftUI.PaymentError",
                    code: PaymentError.unknown.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: PaymentError.unknown.errorDescription ?? "Unknown error"]
                )
                Logger.payment("Payment confirmation failed: \(paymentError.localizedDescription)", level: .error)
                completion(false, paymentError)
            @unknown default:
                Logger.payment("Unknown payment confirmation status", level: .error)
                completion(false, NSError(
                    domain: "com.emerbv.APPECOMM-SwiftUI.PaymentError",
                    code: PaymentError.unknown.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: PaymentError.unknown.errorDescription ?? "Unknown error"]
                ))
            }
        }
    }
    
    /// Errores específicos de pago
    enum PaymentError: Int, Error, LocalizedError {
        case notConfigured = 1001
        case invalidCardDetails = 1002
        case invalidExpiryDate = 1003
        case paymentMethodCreationFailed = 1004
        case paymentIntentCreationFailed = 1005
        case paymentConfirmationFailed = 1006
        case paymentAuthenticationRequired = 1007
        case insufficientFunds = 1008
        case cardDeclined = 1009
        case cardExpired = 1010
        case userCancelled = 1011
        case unknown = 1000
        
        // Resto del código de PaymentError...
        
        // Para convertir a NSError directamente
        func asNSError() -> NSError {
            return NSError(
                domain: "com.emerbv.APPECOMM-SwiftUI.PaymentError",
                code: self.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: self.errorDescription ?? "Unknown error",
                    NSLocalizedRecoverySuggestionErrorKey: self.recoverySuggestion ?? ""
                ]
            )
        }
    }
}
