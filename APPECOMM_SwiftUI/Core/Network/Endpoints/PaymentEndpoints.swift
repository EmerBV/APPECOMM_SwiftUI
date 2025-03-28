//
//  PaymentEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

enum PaymentEndpoints: APIEndpoint {
    case getStripeConfig
    case createPaymentIntent(orderId: Int, request: PaymentRequest)
    case confirmPayment(paymentIntentId: String)
    case cancelPayment(paymentIntentId: String)
    case retrievePayment(paymentIntentId: String)
    
    var path: String {
        switch self {
        case .getStripeConfig:
            return "/stripe-client/config"
        case .createPaymentIntent(let orderId, _):
            return "/payments/checkout/order/\(orderId)"
        case .confirmPayment(let paymentIntentId):
            return "/payments/confirm/\(paymentIntentId)"
        case .cancelPayment(let paymentIntentId):
            return "/payments/cancel/\(paymentIntentId)"
        case .retrievePayment(let paymentIntentId):
            return "/payments/\(paymentIntentId)"
        }
    }
    
    var method: String {
        switch self {
        case .getStripeConfig, .retrievePayment:
            return HTTPMethod.get.rawValue
        case .createPaymentIntent, .confirmPayment, .cancelPayment:
            return HTTPMethod.post.rawValue
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
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
