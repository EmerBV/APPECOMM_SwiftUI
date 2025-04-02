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

struct CreditCardDetails {
    var cardNumber: String = ""
    var expiryDate: String = ""
    var cvv: String = ""
    var cardholderName: String = ""
    
    // Validation states
    var isCardNumberValid: Bool = false
    var isExpiryDateValid: Bool = false
    var isCvvValid: Bool = false
    var isCardholderNameValid: Bool = false
    
    // Error messages
    var cardNumberError: String?
    var expiryDateError: String?
    var cvvError: String?
    var cardholderNameError: String?
    
    var isValid: Bool {
        return isCardNumberValid && isExpiryDateValid && isCvvValid && isCardholderNameValid
    }
    
    /// Initialize with default empty values
    init() {
        // Default initializer with empty values
    }
    
    /// Initialize with provided values
    init(
        cardNumber: String,
        expiryDate: String,
        cvv: String,
        cardholderName: String
    ) {
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.cardholderName = cardholderName
    }
    
    /// Validate all fields
    mutating func validateAll(validator: InputValidatorProtocol = InputValidator()) {
        // Validar número de tarjeta
        let cardNumberResult = validator.validateCreditCardNumber(cardNumber)
        switch cardNumberResult {
        case .valid:
            isCardNumberValid = true
            cardNumberError = nil
        case .invalid(let message):
            isCardNumberValid = false
            cardNumberError = message
        }
        
        // Validar fecha de expiración
        let expiryDateResult = validator.validateExpiryDate(expiryDate)
        switch expiryDateResult {
        case .valid:
            isExpiryDateValid = true
            expiryDateError = nil
        case .invalid(let message):
            isExpiryDateValid = false
            expiryDateError = message
        }
        
        // Validar CVV
        let cvvResult = validator.validateCVV(cvv)
        switch cvvResult {
        case .valid:
            isCvvValid = true
            cvvError = nil
        case .invalid(let message):
            isCvvValid = false
            cvvError = message
        }
        
        // Validar nombre del titular
        let nameResult = validator.validateName(cardholderName)
        switch nameResult {
        case .valid:
            isCardholderNameValid = true
            cardholderNameError = nil
        case .invalid(let message):
            isCardholderNameValid = false
            cardholderNameError = message
        }
    }
    
    /// Reset all fields to empty and invalidate them
    mutating func reset() {
        cardNumber = ""
        expiryDate = ""
        cvv = ""
        cardholderName = ""
        
        isCardNumberValid = false
        isExpiryDateValid = false
        isCvvValid = false
        isCardholderNameValid = false
        
        cardNumberError = nil
        expiryDateError = nil
        cvvError = nil
        cardholderNameError = nil
    }
}

struct StripeCustomer: Codable {
    let id: String
    let email: String
    let name: String?
    let created: Int
    let defaultSource: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case created
        case defaultSource = "default_source"
    }
}
