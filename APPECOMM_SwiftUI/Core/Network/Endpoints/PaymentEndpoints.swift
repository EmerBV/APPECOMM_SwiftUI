//
//  PaymentEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

/*
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
 */

enum PaymentEndpoints: Endpoint {
    case getStripeConfig
    case createPaymentIntent(orderId: Int, request: PaymentRequest)
    case confirmPayment(paymentIntentId: String)
    case cancelPayment(paymentIntentId: String)
    
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
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getStripeConfig:
            return .get
        case .createPaymentIntent, .confirmPayment, .cancelPayment:
            return .post
        }
    }
    
    var headers: [String: String]? {
        // Agregar el token a todos los endpoints que lo requieran
        guard TokenManager.shared.hasValidToken() else {
            return ["Content-Type": "application/json"]
        }
        
        return [
            "Authorization": "Bearer \(TokenManager.shared.getAccessToken() ?? "")",
            "Content-Type": "application/json"
        ]
    }
    
    var body: Data? {
        switch self {
        case .getStripeConfig:
            return nil
        case .createPaymentIntent(_, let request):
            return try? JSONEncoder().encode(request)
        case .confirmPayment, .cancelPayment:
            // Si se necesitan parámetros adicionales, se pueden añadir aquí
            return try? JSONEncoder().encode(EmptyRequest())
        }
    }
    
    var queryParameters: [String: String]? {
        switch self {
        default:
            return nil
        }
    }
    
    // Struct vacío para peticiones POST sin cuerpo
    struct EmptyRequest: Encodable {}
}
