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
