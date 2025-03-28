//
//  CheckoutViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine
import SwiftUI

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

enum CheckoutStep {
    case shippingInfo
    case paymentMethod
    case cardDetails
    case review
    case processing
    case confirmation
    case error
}

enum CardFieldType {
    case number
    case expiry
    case cvv
    case name
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

struct ShippingDetails {
    var fullName = ""
    var address = ""
    var city = ""
    var state = ""
    var postalCode = ""
    var country = ""
    var phoneNumber = ""
    
    // Validation states
    var isFullNameValid = false
    var isAddressValid = false
    var isCityValid = false
    var isStateValid = false
    var isPostalCodeValid = false
    var isCountryValid = false
    var isPhoneNumberValid = false
    
    var isValid: Bool {
        return isFullNameValid && isAddressValid && isCityValid &&
               isStateValid && isPostalCodeValid && isCountryValid && isPhoneNumberValid
    }
    
    init(fromUser user: User? = nil) {
        if let shipping = user?.shippingDetails {
            self.fullName = "\(user?.firstName ?? "") \(user?.lastName ?? "")"
            self.address = shipping.address ?? ""
            self.city = shipping.city ?? ""
            self.postalCode = shipping.postalCode ?? ""
            self.country = shipping.country ?? ""
            self.phoneNumber = shipping.phoneNumber ?? ""
            
            // Set basic validation based on presence of data
            self.isFullNameValid = !self.fullName.isEmpty
            self.isAddressValid = !self.address.isEmpty
            self.isCityValid = !self.city.isEmpty
            self.isPostalCodeValid = !self.postalCode.isEmpty
            self.isCountryValid = !self.country.isEmpty
            self.isPhoneNumberValid = !self.phoneNumber.isEmpty
        }
    }
}

class CheckoutViewModel: ObservableObject {
    // Published properties for UI state
    @Published var currentStep: CheckoutStep = .shippingInfo
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    @Published var shippingDetails = ShippingDetails()
    @Published var creditCardDetails = CreditCardDetails()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var paymentIntentId: String?
    @Published var clientSecret: String?
    @Published var cart: Cart?
    @Published var orderSummary: OrderSummary?
    
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
        
        // Prepare order summary from cart
        if let cart = cart {
            self.orderSummary = OrderSummary(
                subtotal: cart.totalAmount,
                tax: calculateTax(cart.totalAmount),
                shipping: calculateShipping(cart.totalAmount),
                total: cart.totalAmount + calculateTax(cart.totalAmount) + calculateShipping(cart.totalAmount)
            )
        }
        
        // Load shipping details from user profile if available
        loadUserShippingDetails()
    }
    
    private func loadUserShippingDetails() {
        // Get current user if logged in
        if case let .loggedIn(user) = authRepository.authState.value {
            self.shippingDetails = ShippingDetails(fromUser: user)
        }
    }
    
    private func calculateTax(_ amount: Decimal) -> Decimal {
        // Calculate tax as 7% of subtotal
        return (amount * Decimal(0.07)).rounded(2)
    }
    
    private func calculateShipping(_ amount: Decimal) -> Decimal {
        // Free shipping for orders over $50, otherwise $5.99
        return amount > 50 ? 0 : Decimal(5.99)
    }
    
    // Validation methods
    func validateCardNumber(_ number: String) -> Bool {
        // Basic validation: 16 digits, passing Luhn algorithm
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == 16, cleaned.allSatisfy({ $0.isNumber }) else {
            return false
        }
        
        // TODO: Implement Luhn algorithm for proper validation
        // For now, we'll just check that it starts with common prefixes
        let validPrefixes = ["4", "5", "3", "6"] // Visa, MC, Amex, Discover
        return validPrefixes.contains(String(cleaned.prefix(1)))
    }
    
    func validateExpiryDate(_ date: String) -> Bool {
        // Format should be MM/YY
        let components = date.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]),
              month >= 1, month <= 12 else {
            return false
        }
        
        // Get current date components
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date()) % 100
        let currentMonth = calendar.component(.month, from: Date())
        
        // Validate that date is in the future
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
    
    // Payment processing methods
    func createPaymentIntent() {
        guard let cart = cart, let orderSummary = orderSummary else {
            self.errorMessage = "Missing cart or order information"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // This would be replaced with actual payment method ID from Stripe SDK in a real implementation
        let mockPaymentMethodId = "pm_card_visa"
        
        let request = PaymentRequest(
            orderId: cart.cartId,
            paymentMethodId: mockPaymentMethodId,
            currency: "usd",
            receiptEmail: nil,
            description: "Payment for Order #\(cart.cartId)"
        )
        
        paymentService.createPaymentIntent(orderId: cart.cartId, request: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Payment initialization failed: \(error.localizedDescription)"
                    self?.currentStep = .error
                }
            } receiveValue: { [weak self] response in
                self?.paymentIntentId = response.paymentIntentId
                self?.clientSecret = response.clientSecret
                
                // In a real implementation, we would use the client secret with the Stripe SDK
                // For now, we'll simulate a successful payment
                self?.simulatePaymentProcessing()
            }
            .store(in: &cancellables)
    }
    
    private func simulatePaymentProcessing() {
        self.currentStep = .processing
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            // 90% chance of success for demo purposes
            let success = Int.random(in: 1...10) <= 9
            
            if success {
                self?.successMessage = "Payment processed successfully!"
                self?.currentStep = .confirmation
            } else {
                self?.errorMessage = "Payment processing failed. Please try again."
                self?.currentStep = .error
            }
            
            self?.isLoading = false
        }
    }
    
    // Navigation methods
    func proceedToNextStep() {
        switch currentStep {
        case .shippingInfo:
            if shippingDetails.isValid {
                currentStep = .paymentMethod
            } else {
                errorMessage = "Please complete all shipping information"
            }
            
        case .paymentMethod:
            switch selectedPaymentMethod {
            case .creditCard:
                currentStep = .cardDetails
            case .applePay:
                // In a real implementation, we would launch Apple Pay here
                currentStep = .review
            }
            
        case .cardDetails:
            if creditCardDetails.isValid {
                currentStep = .review
            } else {
                errorMessage = "Please complete all card details correctly"
            }
            
        case .review:
            // Start payment processing
            createPaymentIntent()
            
        case .processing:
            // Wait for processing to complete
            break
            
        case .confirmation, .error:
            // Reset to first step or return to cart
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
            // For other steps, stay on current step or handle specially
            break
        }
    }
    
    // Card field formatting methods
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
}

// Helper struct for order summary
struct OrderSummary {
    let subtotal: Decimal
    let tax: Decimal
    let shipping: Decimal
    let total: Decimal
    
    var formattedSubtotal: String { subtotal.toCurrentLocalePrice }
    var formattedTax: String { tax.toCurrentLocalePrice }
    var formattedShipping: String { shipping > 0 ? shipping.toCurrentLocalePrice : "Free" }
    var formattedTotal: String { total.toCurrentLocalePrice }
}
