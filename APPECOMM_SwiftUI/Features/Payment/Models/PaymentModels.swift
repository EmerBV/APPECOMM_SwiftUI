import Foundation

// MARK: - Payment Models
struct PaymentRequest: Codable {
    let paymentMethodId: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentMethodId = "payment_method_id"
    }
}

struct PaymentIntentResponse: Codable {
    let paymentIntentId: String
    let clientSecret: String
    let order: Order
    
    enum CodingKeys: String, CodingKey {
        case paymentIntentId = "paymentIntentId"
        case clientSecret = "clientSecret"
        case order
    }
}

struct PaymentConfirmationResponse: Codable {
    let success: Bool
    let message: String
}

struct StripeConfig: Codable {
    let publicKey: String
    let currency: String
    let locale: String
    
    enum CodingKeys: String, CodingKey {
        case publicKey
        case currency
        case locale
    }
}

// MARK: - Payment Errors
/*
 enum PaymentError: LocalizedError {
 case invalidPaymentMethod
 case paymentFailed(String)
 case invalidAmount
 case networkError
 
 var errorDescription: String? {
 switch self {
 case .invalidPaymentMethod:
 return "El método de pago no es válido"
 case .paymentFailed(let message):
 return "El pago falló: \(message)"
 case .invalidAmount:
 return "El monto del pago no es válido"
 case .networkError:
 return "Error de conexión. Por favor, intente nuevamente"
 }
 }
 }
 */
