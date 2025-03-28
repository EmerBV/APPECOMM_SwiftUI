//
//  CheckoutViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

enum CheckoutStep {
    case shippingInfo
    case paymentMethod
    case cardDetails
    case review
    case processing
    case confirmation
    case error
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case creditCard = "credit_card"
    case applePay = "apple_pay"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .applePay:
            return "Apple Pay"
        }
    }
    
    var iconName: String {
        switch self {
        case .creditCard:
            return "creditcard.fill"
        case .applePay:
            return "apple.logo"
        }
    }
}

struct CreditCardDetails {
    var cardNumber = ""
    var cardholderName = ""
    var expiryDate = ""
    var cvv = ""
    
    // Validation states
    var isCardNumberValid = false
    var isCardholderNameValid = false
    var isExpiryDateValid = false
    var isCvvValid = false
    
    var isValid: Bool {
        return isCardNumberValid && isCardholderNameValid && isExpiryDateValid && isCvvValid
    }
}

struct OrderSummaryCheckout {
    var subtotal: Decimal = 0
    var shippingCost: Decimal = 0
    var tax: Decimal = 0
    var total: Decimal = 0
    
    var formattedSubtotal: String { subtotal.toCurrentLocalePrice }
    var formattedShipping: String { shippingCost > 0 ? shippingCost.toCurrentLocalePrice : "Gratis" }
    var formattedTax: String { tax.toCurrentLocalePrice }
    var formattedTotal: String { total.toCurrentLocalePrice }
}

class CheckoutViewModel: ObservableObject {
    // Published properties for UI state
    @Published var currentStep: CheckoutStep = .shippingInfo
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    @Published var shippingDetailsForm = ShippingDetailsForm()
    @Published var creditCardDetails = CreditCardDetails()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var paymentIntentId: String?
    @Published var clientSecret: String?
    @Published var cart: Cart?
    @Published var orderSummary = OrderSummaryCheckout()
    
    // Dependencies
    private let paymentService: PaymentServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cart: Cart?,
        paymentService: PaymentServiceProtocol,
        authRepository: AuthRepositoryProtocol,
        validator: InputValidatorProtocol
    ) {
        self.cart = cart
        self.paymentService = paymentService
        self.authRepository = authRepository
        self.validator = validator
        
        // Calculate order summary based on cart
        if let cart = cart {
            calculateOrderSummary(from: cart)
        }
        
        // Load user shipping details if available
        loadUserShippingDetails()
    }
    
    private func loadUserShippingDetails() {
        // If user is authenticated, load their shipping details
        if case let .loggedIn(user) = authRepository.authState.value, let userShipping = user.shippingDetails {
            self.shippingDetailsForm.update(from: userShipping)
        }
    }
    
    private func calculateOrderSummary(from cart: Cart) {
        self.orderSummary.subtotal = cart.totalAmount
        
        // Calculate tax (example: 8% of subtotal)
        self.orderSummary.tax = calculateTax(orderSummary.subtotal)
        
        // Determine shipping cost (free for orders over $50)
        self.orderSummary.shippingCost = calculateShipping(orderSummary.subtotal)
        
        // Calculate total
        self.orderSummary.total = orderSummary.subtotal + orderSummary.tax + orderSummary.shippingCost
    }
    
    private func calculateTax(_ amount: Decimal) -> Decimal {
        // Example: 8% tax
        return (amount * Decimal(0.08)).rounded(2)
    }
    
    private func calculateShipping(_ amount: Decimal) -> Decimal {
        // Free shipping for purchases over $50, otherwise $5.99
        return amount > 50 ? 0 : Decimal(5.99)
    }
    
    // MARK: - Card Validation
    
    func validateCardNumber(_ number: String) -> Bool {
        // Basic validation: 16 digits, starting with common prefixes
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == 16, cleaned.allSatisfy({ $0.isNumber }) else {
            return false
        }
        
        // Check common prefixes (Visa, MC, Amex, Discover)
        let validPrefixes = ["4", "5", "3", "6"]
        return validPrefixes.contains(String(cleaned.prefix(1)))
    }
    
    func validateExpiryDate(_ date: String) -> Bool {
        // Format must be MM/YY
        let components = date.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]),
              month >= 1, month <= 12 else {
            return false
        }
        
        // Verify date is in the future
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date()) % 100
        let currentMonth = calendar.component(.month, from: Date())
        
        return (year > currentYear) || (year == currentYear && month >= currentMonth)
    }
    
    func validateCVV(_ cvv: String) -> Bool {
        // Usually 3 or 4 digits
        let cleaned = cvv.replacingOccurrences(of: " ", with: "")
        return cleaned.count >= 3 && cleaned.count <= 4 && cleaned.allSatisfy({ $0.isNumber })
    }
    
    func validateCardholderName(_ name: String) -> Bool {
        // At least two names, only letters and spaces
        let names = name.split(separator: " ")
        return names.count >= 2 && name.allSatisfy({ $0.isLetter || $0.isWhitespace })
    }
    
    // MARK: - Payment Processing
    
    func createPaymentIntent() {
        guard let cart = cart else {
            self.errorMessage = "No cart available"
            return
        }
        
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "No authenticated user"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // In a real case, we would first create an order on the server
        // and then generate the PaymentIntent for that order
        
        // For this implementation, we'll simulate the process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Simulate success in creating the PaymentIntent
            self?.paymentIntentId = "pi_simulated_\(UUID().uuidString)"
            self?.clientSecret = "seti_simulated_\(UUID().uuidString)"
            
            // Proceed to payment processing
            self?.simulatePaymentProcessing()
        }
    }
    
    private func simulatePaymentProcessing() {
        self.currentStep = .processing
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            // For demonstration, we simulate 90% success
            let success = Int.random(in: 1...10) <= 9
            
            if success {
                self?.successMessage = "Payment processed successfully"
                self?.currentStep = .confirmation
            } else {
                self?.errorMessage = "Payment processing failed. Please try again."
                self?.currentStep = .error
            }
            
            self?.isLoading = false
        }
    }
    
    // MARK: - Navigation
    
    func proceedToNextStep() {
        switch currentStep {
        case .shippingInfo:
            if shippingDetailsForm.isValid {
                currentStep = .paymentMethod
            } else {
                errorMessage = "Please complete all shipping information"
            }
            
        case .paymentMethod:
            switch selectedPaymentMethod {
            case .creditCard:
                currentStep = .cardDetails
            case .applePay:
                // In a real case, we would launch Apple Pay here
                currentStep = .review
            }
            
        case .cardDetails:
            if creditCardDetails.isValid {
                currentStep = .review
            } else {
                errorMessage = "Please correctly complete all card details"
            }
            
        case .review:
            // Start payment processing
            createPaymentIntent()
            
        case .processing:
            // Wait for processing to finish
            break
            
        case .confirmation, .error:
            // Return to cart or main screen
            break
        }
    }
    
    func goBack() {
        switch currentStep {
        case .paymentMethod:
            currentStep = .shippingInfo
        case .cardDetails:
            currentStep = .paymentMethod
        case .review:
            if selectedPaymentMethod == .creditCard {
                currentStep = .cardDetails
            } else {
                currentStep = .paymentMethod
            }
        default:
            // For other steps, stay on the current step
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> Int? {
        if case let .loggedIn(user) = authRepository.authState.value {
            return user.id
        }
        return nil
    }
    
    // Card formatting
    func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted.append(" ")
            }
            formatted.append(char)
        }
        
        return formatted
    }
    
    func formatExpiryDate(_ date: String) -> String {
        let cleaned = date.replacingOccurrences(of: "/", with: "")
        
        if cleaned.count > 2 {
            let month = cleaned.prefix(2)
            let year = cleaned.dropFirst(2)
            return "\(month)/\(year)"
        }
        
        return cleaned
    }
    
    // Convert ShippingDetailsForm to ShippingDetails model
    func createShippingDetails() -> ShippingDetails {
        return ShippingDetails(
            id: nil,
            address: shippingDetailsForm.address,
            city: shippingDetailsForm.city,
            postalCode: shippingDetailsForm.postalCode,
            country: shippingDetailsForm.country,
            phoneNumber: shippingDetailsForm.phoneNumber
        )
    }
}

// Form model for collecting shipping details with validation
struct ShippingDetailsForm {
    var fullName: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = ""
    var phoneNumber: String = ""
    
    // Validation states
    var isFullNameValid: Bool = false
    var isAddressValid: Bool = false
    var isCityValid: Bool = false
    var isStateValid: Bool = false
    var isPostalCodeValid: Bool = false
    var isCountryValid: Bool = false
    var isPhoneNumberValid: Bool = false
    
    var isValid: Bool {
        return isFullNameValid && isAddressValid && isCityValid &&
        isStateValid && isPostalCodeValid && isCountryValid && isPhoneNumberValid
    }
    
    // Update from existing ShippingDetails
    mutating func update(from details: ShippingDetails) {
        if let address = details.address {
            self.address = address
            self.isAddressValid = !address.isEmpty
        }
        
        if let city = details.city {
            self.city = city
            self.isCityValid = !city.isEmpty
        }
        
        if let postalCode = details.postalCode {
            self.postalCode = postalCode
            self.isPostalCodeValid = !postalCode.isEmpty
        }
        
        if let country = details.country {
            self.country = country
            self.isCountryValid = !country.isEmpty
        }
        
        if let phoneNumber = details.phoneNumber {
            self.phoneNumber = phoneNumber
            self.isPhoneNumberValid = !phoneNumber.isEmpty
        }
    }
}
