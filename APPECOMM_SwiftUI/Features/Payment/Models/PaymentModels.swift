import Foundation

// MARK: - Payment Status
enum PaymentStatus {
    case idle
    case loading
    case ready
    case processing
    case completed
    case failed(String)
}

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
