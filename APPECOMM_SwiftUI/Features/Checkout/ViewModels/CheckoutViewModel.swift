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
    
    // Shipping details related properties
    @Published var existingShippingDetails: ShippingDetailsResponse?
    @Published var hasExistingShippingDetails = false
    @Published var isEditingShippingDetails = false
    
    // Dependencies
    private let paymentService: PaymentServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    private let shippingService: ShippingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cart: Cart?,
        paymentService: PaymentServiceProtocol,
        authRepository: AuthRepositoryProtocol,
        validator: InputValidatorProtocol,
        shippingService: ShippingServiceProtocol = DependencyInjector.shared.resolve(ShippingServiceProtocol.self)
    ) {
        self.cart = cart
        self.paymentService = paymentService
        self.authRepository = authRepository
        self.validator = validator
        self.shippingService = shippingService
        
        // Calculate order summary based on cart
        if let cart = cart {
            calculateOrderSummary(from: cart)
        }
        
        // Load existing shipping details if available
        loadExistingShippingDetails()
    }
    
    // MARK: - Order Summary Calculation
    
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
    
    // MARK: - Shipping Details Management
    
    /// Load existing shipping details for the user
    private func loadExistingShippingDetails() {
        guard let userId = getCurrentUserId() else { return }
        
        isLoading = true
        errorMessage = nil
        
        shippingService.getShippingDetails(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error loading shipping details: \(error)")
                    // No mostrar el error al usuario, simplemente usar un formulario en blanco
                    self?.hasExistingShippingDetails = false
                    self?.isEditingShippingDetails = true
                }
            } receiveValue: { [weak self] details in
                guard let self = self else { return }
                
                if let details = details {
                    // Guardar los detalles existentes
                    self.existingShippingDetails = details
                    self.hasExistingShippingDetails = true
                    self.isEditingShippingDetails = false
                    
                    // Poblar el formulario con los detalles existentes
                    self.populateFormWithExistingDetails(details)
                    
                    Logger.info("Loaded existing shipping details for user")
                } else {
                    // No hay detalles de envío, mostrar formulario en blanco
                    self.hasExistingShippingDetails = false
                    self.isEditingShippingDetails = true
                    Logger.info("No existing shipping details found, showing empty form")
                }
            }
            .store(in: &cancellables)
    }
    
    /// Populate the form with existing shipping details
    private func populateFormWithExistingDetails(_ details: ShippingDetailsResponse) {
        shippingDetailsForm.fullName = details.fullName ?? ""
        shippingDetailsForm.address = details.address
        shippingDetailsForm.city = details.city
        shippingDetailsForm.state = details.state ?? ""
        shippingDetailsForm.postalCode = details.postalCode
        shippingDetailsForm.country = details.country
        shippingDetailsForm.phoneNumber = details.phoneNumber ?? ""
        
        // Validar el formulario
        validateShippingForm()
    }
    
    /// Validate all fields in the shipping form
    private func validateShippingForm() {
        shippingDetailsForm.isFullNameValid = !shippingDetailsForm.fullName.isEmpty
        shippingDetailsForm.isAddressValid = !shippingDetailsForm.address.isEmpty
        shippingDetailsForm.isCityValid = !shippingDetailsForm.city.isEmpty
        shippingDetailsForm.isStateValid = !shippingDetailsForm.state.isEmpty
        shippingDetailsForm.isPostalCodeValid = !shippingDetailsForm.postalCode.isEmpty
        shippingDetailsForm.isCountryValid = !shippingDetailsForm.country.isEmpty
        shippingDetailsForm.isPhoneNumberValid = !shippingDetailsForm.phoneNumber.isEmpty
    }
    
    /// Save or update shipping details
    func saveShippingDetails() {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "No authenticated user"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // Create shipping details request object from form
        let shippingDetailsRequest = ShippingDetailsRequest(
            address: shippingDetailsForm.address,
            city: shippingDetailsForm.city,
            state: shippingDetailsForm.state,
            postalCode: shippingDetailsForm.postalCode,
            country: shippingDetailsForm.country,
            phoneNumber: shippingDetailsForm.phoneNumber,
            fullName: shippingDetailsForm.fullName
        )
        
        // Call API to save shipping details
        shippingService.updateShippingDetails(userId: userId, details: shippingDetailsRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to save shipping details: \(error.localizedDescription)"
                    Logger.error("Error saving shipping details: \(error)")
                }
            } receiveValue: { [weak self] details in
                guard let self = self else { return }
                
                Logger.info("Shipping details saved successfully")
                
                // Actualizar los detalles existentes
                self.existingShippingDetails = details
                self.hasExistingShippingDetails = true
                self.isEditingShippingDetails = false
                
                // Continuar con el flujo de checkout
                self.currentStep = .paymentMethod
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Credit Card Validation
    
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
    
    // MARK: - Navigation
    
    func proceedToNextStep() {
        switch currentStep {
        case .shippingInfo:
            if hasExistingShippingDetails && !isEditingShippingDetails {
                // Si tiene detalles existentes y no está editando, puede continuar directamente
                currentStep = .paymentMethod
            } else if shippingDetailsForm.isValid {
                // Guarda los detalles de envío y continúa
                saveShippingDetails()
            } else {
                errorMessage = "Please complete all shipping information"
            }
            
        case .paymentMethod:
            switch selectedPaymentMethod {
            case .creditCard:
                currentStep = .cardDetails
            case .applePay:
                // En un caso real, aquí lanzaríamos Apple Pay
                currentStep = .review
            }
            
        case .cardDetails:
            if creditCardDetails.isValid {
                currentStep = .review
            } else {
                errorMessage = "Please correctly complete all card details"
            }
            
        case .review:
            // Iniciar procesamiento de pago
            createPaymentIntent()
            
        case .processing:
            // Esperar a que finalice el procesamiento
            break
            
        case .confirmation, .error:
            // Volver a la pantalla principal o al carrito
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
            // Para otras etapas, permanecer en la etapa actual
            break
        }
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
        
        // En un caso real, primero crearíamos una orden en el servidor
        // y luego generaríamos el PaymentIntent para esa orden
        
        // Para esta implementación, simularemos el proceso
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Simular éxito en la creación del PaymentIntent
            self?.paymentIntentId = "pi_simulated_\(UUID().uuidString)"
            self?.clientSecret = "seti_simulated_\(UUID().uuidString)"
            
            // Proceder con el procesamiento del pago
            self?.simulatePaymentProcessing()
        }
    }
    
    private func simulatePaymentProcessing() {
        self.currentStep = .processing
        
        // Simular tiempo de procesamiento
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            // Para demostración, simulamos un 90% de éxito
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
    
    // MARK: - Helper Methods
    
    func getCurrentUserId() -> Int? {
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
}

// Form model for shipping details with validation
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
}
