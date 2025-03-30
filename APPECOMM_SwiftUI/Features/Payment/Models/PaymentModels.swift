import Foundation

// MARK: - Payment Models
struct PaymentRequest: Codable {
    let paymentMethodId: String?
    let currency: String
    let receiptEmail: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentMethodId
        case currency
        case receiptEmail
        case description
    }
    
    init(paymentMethodId: String? = nil,
         currency: String = "usd",
         receiptEmail: String? = nil,
         description: String? = nil) {
        self.paymentMethodId = paymentMethodId
        self.currency = currency
        self.receiptEmail = receiptEmail
        self.description = description
    }
}

struct PaymentIntentResponse: Codable {
    let paymentIntentId: String
    let clientSecret: String
    let status: String
}

struct PaymentConfirmationResponse: Codable {
    let success: Bool
    let message: String?
}

struct StripeConfig: Codable {
    let publishableKey: String
    let merchantId: String?
    let countryCode: String
}

// MARK: - Payment Errors
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