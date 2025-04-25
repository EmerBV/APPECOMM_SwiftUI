//
//  PaymentEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

enum PaymentEndpoints {
    case getStripeConfig
    case createPaymentIntent(orderId: Int, request: PaymentRequest)
    case confirmPaymentIntent(paymentIntentId: String, paymentMethodId: String)
    case cancelPaymentIntent(paymentIntentId: String)
    case createPaymentMethod(cardDetails: CreditCardDetails)
    case createCustomer(userId: Int, email: String)
    case createEphemeralKey(customerId: String)
}

extension PaymentEndpoints: APIEndpoint {
    var path: String {
        switch self {
        case .getStripeConfig:
            return "/stripe-client/config"
        case .createPaymentIntent(let orderId, _):
            return "/payments/checkout/order/\(orderId)"
        case .confirmPaymentIntent(let paymentIntentId, _):
            return "/payments/confirm/\(paymentIntentId)"
        case .cancelPaymentIntent(let paymentIntentId):
            return "/payments/cancel/\(paymentIntentId)"
        case .createPaymentMethod:
            return "/payments/payment-methods"
        case .createCustomer:
            return "/stripe-client/customer"
        case .createEphemeralKey(let customerId):
            return "/stripe-client/ephemeral-key/\(customerId)"
        }
    }
    
    var method: String {
        switch self {
        case .getStripeConfig:
            return HTTPMethod.get.rawValue
        case .createPaymentIntent, .confirmPaymentIntent, .createPaymentMethod, .createCustomer, .createEphemeralKey:
            return HTTPMethod.post.rawValue
        case .cancelPaymentIntent:
            return HTTPMethod.delete.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .createPaymentIntent(_, let request):
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
            
        case .confirmPaymentIntent(_, let paymentMethodId):
            return ["payment_method_id": paymentMethodId]
            
        case .createPaymentMethod(let cardDetails):
            // Crear objeto para enviar solo los datos necesarios
            return [
                "card": [
                    "number": cardDetails.cardNumber.replacingOccurrences(of: " ", with: ""),
                    "exp_month": Int(cardDetails.expiryDate.prefix(2)) ?? 0,
                    "exp_year": Int("20" + String(cardDetails.expiryDate.suffix(2))) ?? 0,
                    "cvc": cardDetails.cvv
                ],
                "billing_details": [
                    "name": cardDetails.cardholderName
                ],
                "type": "card"
            ]
            
        case .createCustomer(_, let email):
            return ["email": email]
            
        default:
            return nil
        }
    }
    
    var headers: [String: String]? {
        return nil // Usar los headers por defecto de APIConfiguration
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .getStripeConfig, .cancelPaymentIntent:
            return .url
        default:
            return .json
        }
    }
    
    var requiresAuthentication: Bool {
        // Todos los endpoints de pago requieren autenticación excepto la configuración
        switch self {
        case .getStripeConfig:
            return false
        default:
            return true
        }
    }
}
