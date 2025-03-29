//
//  StripeService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Stripe
import Combine
import StripePaymentSheet
import UIKit

/*
 protocol StripeServiceProtocol {
 //func createPaymentMethod(cardDetails: CreditCardDetails) -> Future<STPPaymentMethod, Error>
 func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, Error>
 func confirmPayment(paymentIntentClientSecret: String, paymentMethodId: String) -> AnyPublisher<Bool, Error>
 }
 
 class StripeService: StripeServiceProtocol {
 
 func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, Error> {
 return Future<String, Error> { promise in
 // Crear un PaymentMethod en lugar de un Token
 let cardParams = STPPaymentMethodCardParams()
 cardParams.number = cardDetails.cardNumber.replacingOccurrences(of: " ", with: "")
 
 // Parsear la fecha de expiración MM/YY
 let expiryComponents = cardDetails.expiryDate.split(separator: "/")
 if expiryComponents.count == 2,
 let month = UInt(expiryComponents[0]),
 let year = UInt("20" + String(expiryComponents[1])) {
 cardParams.expMonth = NSNumber(value: month)
 cardParams.expYear = NSNumber(value: year)
 }
 
 cardParams.cvc = cardDetails.cvv
 
 // Crear los parámetros del método de pago
 let billingDetails = STPPaymentMethodBillingDetails()
 billingDetails.name = cardDetails.cardholderName
 
 let paymentMethodParams = STPPaymentMethodParams(
 card: cardParams,
 billingDetails: billingDetails,
 metadata: nil
 )
 
 // Crear el método de pago en Stripe
 STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
 if let error = error {
 Logger.error("Error creating payment method: \(error.localizedDescription)")
 promise(.failure(error))
 return
 }
 
 guard let paymentMethod = paymentMethod else {
 let error = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0, userInfo: [NSLocalizedDescriptionKey: "No payment method created"])
 Logger.error("Payment method is nil")
 promise(.failure(error))
 return
 }
 
 Logger.info("Payment method created: \(paymentMethod.stripeId)")
 promise(.success(paymentMethod.stripeId))
 }
 }.eraseToAnyPublisher()
 }
 
 func confirmPayment(paymentIntentClientSecret: String, paymentMethodId: String) -> AnyPublisher<Bool, Error> {
 // Implementación simplificada para la demo
 return Just(true)
 .setFailureType(to: Error.self)
 .eraseToAnyPublisher()
 }
 }
 */

protocol StripeServiceProtocol {
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, Error>
    func confirmPayment(paymentIntentClientSecret: String, paymentMethodId: String) -> AnyPublisher<Bool, Error>
    func configureStripe(publishableKey: String)
}

class StripeService: StripeServiceProtocol {
    // Configurar Stripe con la clave publicable
    func configureStripe(publishableKey: String) {
        StripeAPI.defaultPublishableKey = publishableKey
        Logger.info("Stripe configured with publishable key")
    }
    
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // Validar los datos de la tarjeta antes de enviarlos
            if cardDetails.cardNumber.isEmpty || cardDetails.expiryDate.isEmpty || cardDetails.cvv.isEmpty {
                let error = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Invalid card details"])
                promise(.failure(error))
                return
            }
            
            // Crear un PaymentMethod en lugar de un Token
            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = cardDetails.cardNumber.replacingOccurrences(of: " ", with: "")
            
            // Parsear la fecha de expiración MM/YY
            let expiryComponents = cardDetails.expiryDate.split(separator: "/")
            if expiryComponents.count == 2,
               let month = UInt(expiryComponents[0]),
               let year = UInt("20" + String(expiryComponents[1])) {
                cardParams.expMonth = NSNumber(value: month)
                cardParams.expYear = NSNumber(value: year)
            } else {
                let error = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Invalid expiry date format"])
                promise(.failure(error))
                return
            }
            
            cardParams.cvc = cardDetails.cvv
            
            // Crear los parámetros del método de pago
            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.name = cardDetails.cardholderName
            
            let paymentMethodParams = STPPaymentMethodParams(
                card: cardParams,
                billingDetails: billingDetails,
                metadata: nil
            )
            
            // Log para depuración
            Logger.debug("Creating payment method with card: **** **** **** \(cardDetails.cardNumber.suffix(4))")
            
            // Crear el método de pago en Stripe
            STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                if let error = error {
                    Logger.error("Error creating payment method: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                guard let paymentMethod = paymentMethod else {
                    let error = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "No payment method created"])
                    Logger.error("Payment method is nil")
                    promise(.failure(error))
                    return
                }
                
                Logger.info("Payment method created successfully: \(paymentMethod.stripeId)")
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
    
    func confirmPayment(paymentIntentClientSecret: String, paymentMethodId: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            // Validar los datos de entrada
            if paymentIntentClientSecret.isEmpty || paymentMethodId.isEmpty {
                let error = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Empty payment intent or payment method"])
                promise(.failure(error))
                return
            }
            
            // Configurar los parámetros para confirmar el pago
            let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
            paymentIntentParams.paymentMethodId = paymentMethodId
            
            // Usar el contexto de autenticación adaptado para SwiftUI
            let authContext = SwiftUIAuthenticationContext()
            
            // Confirmar el pago
            STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: authContext) { status, _, error in
                switch status {
                case .succeeded:
                    Logger.info("Payment confirmation succeeded")
                    promise(.success(true))
                case .canceled:
                    Logger.info("Payment confirmation canceled")
                    // Devolvemos false para indicar cancelación
                    promise(.success(false))
                case .failed:
                    if let error = error {
                        Logger.error("Payment confirmation failed: \(error.localizedDescription)")
                        promise(.failure(error))
                    } else {
                        let unknownError = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0,
                                                   userInfo: [NSLocalizedDescriptionKey: "Payment failed with unknown error"])
                        promise(.failure(unknownError))
                    }
                @unknown default:
                    let unknownError = NSError(domain: "com.emerbv.APPECOMM-SwiftUI", code: 0,
                                               userInfo: [NSLocalizedDescriptionKey: "Unknown payment status"])
                    promise(.failure(unknownError))
                }
            }
        }.eraseToAnyPublisher()
    }
}
