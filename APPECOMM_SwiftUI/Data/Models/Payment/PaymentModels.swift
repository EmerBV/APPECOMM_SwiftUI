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

struct CustomerPaymentMethod: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let stripePaymentMethodId: String
    let type: String
    let last4: String
    let brand: String
    let expiryMonth: Int
    let expiryYear: Int
    let isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case stripePaymentMethodId = "stripe_payment_method_id"
        case type
        case last4
        case brand
        case expiryMonth = "expiry_month"
        case expiryYear = "expiry_year"
        case isDefault = "is_default"
    }
    
    static func == (lhs: CustomerPaymentMethod, rhs: CustomerPaymentMethod) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PaymentTransaction: Identifiable, Codable, Equatable {
    let id: Int
    let paymentIntentId: String
    let amount: Decimal
    let currency: String
    let status: String
    let paymentMethod: String
    let paymentDate: String
    let orderId: Int
    let errorMessage: String?
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case paymentIntentId = "payment_intent_id"
        case amount
        case currency
        case status
        case paymentMethod = "payment_method"
        case paymentDate = "payment_date"
        case orderId = "order_id"
        case errorMessage = "error_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: PaymentTransaction, rhs: PaymentTransaction) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PaymentMethod: Identifiable, Codable, Equatable {
    let id: String
    let type: String
    let card: PaymentCard?
    let billingDetails: BillingDetails?
    let customerId: String?
    let isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case card
        case billingDetails = "billing_details"
        case customerId = "customer"
        case isDefault = "is_default"
    }
    
    static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PaymentCard: Codable, Equatable {
    let brand: String
    let last4: String
    let expiryMonth: Int
    let expiryYear: Int
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case brand
        case last4
        case expiryMonth = "exp_month"
        case expiryYear = "exp_year"
        case country
    }
}

struct BillingDetails: Codable, Equatable {
    let address: PaymentAddress?
    let email: String?
    let name: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case address
        case email
        case name
        case phone
    }
}

struct PaymentAddress: Codable, Equatable {
    let city: String?
    let country: String?
    let line1: String?
    let line2: String?
    let postalCode: String?
    let state: String?
    
    enum CodingKeys: String, CodingKey {
        case city
        case country
        case line1
        case line2
        case postalCode = "postal_code"
        case state
    }
}
