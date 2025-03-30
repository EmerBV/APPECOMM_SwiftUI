//
//  CheckoutViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine
import SwiftUI

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
            return "Tarjeta de crédito"
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

/// Credit card details model with validation
struct CreditCardDetails {
    var cardNumber: String = ""
    var cardholderName: String = ""
    var expiryDate: String = ""
    var cvv: String = ""
    
    // Validation states
    var isCardNumberValid: Bool = false
    var isCardholderNameValid: Bool = false
    var isExpiryDateValid: Bool = false
    var isCvvValid: Bool = false
    
    // Validation error messages
    var cardNumberError: String?
    var cardholderNameError: String?
    var expiryDateError: String?
    var cvvError: String?
    
    /// Check if all fields are valid
    var isValid: Bool {
        return isCardNumberValid && isCardholderNameValid && isExpiryDateValid && isCvvValid
    }
    
    /// Initialize with default empty values
    init() {
        // Default initializer with empty values
    }
    
    /// Initialize with values and validate
    init(cardNumber: String, cardholderName: String, expiryDate: String, cvv: String) {
        self.cardNumber = cardNumber
        self.cardholderName = cardholderName
        self.expiryDate = expiryDate
        self.cvv = cvv
        
        self.validateAll()
    }
    
    /// Validate all fields using a validator
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
        
        // Validar fecha de expiración
        let expiryResult = validator.validateExpiryDate(expiryDate)
        switch expiryResult {
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
    }
    
    /// Reset all fields to empty and invalidate them
    mutating func reset() {
        cardNumber = ""
        cardholderName = ""
        expiryDate = ""
        cvv = ""
        
        isCardNumberValid = false
        isCardholderNameValid = false
        isExpiryDateValid = false
        isCvvValid = false
        
        cardNumberError = nil
        cardholderNameError = nil
        expiryDateError = nil
        cvvError = nil
    }
    
    /// Format card number for display (groups of 4 digits)
    func formattedCardNumber() -> String {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted.append(" ")
            }
            formatted.append(char)
        }
        
        return formatted
    }
    
    /// Format expiry date for display (MM/YY)
    func formattedExpiryDate() -> String {
        let cleaned = expiryDate.replacingOccurrences(of: "/", with: "")
        
        if cleaned.count > 2 {
            let month = cleaned.prefix(2)
            let year = cleaned.dropFirst(2)
            return "\(month)/\(year)"
        }
        
        return cleaned
    }
    
    /// Get card brand from first digit
    func cardBrand() -> String {
        guard !cardNumber.isEmpty else {
            return "Unknown"
        }
        
        let firstChar = cardNumber.first!
        
        switch firstChar {
        case "4":
            return "Visa"
        case "5":
            return "Mastercard"
        case "3":
            return "American Express"
        case "6":
            return "Discover"
        default:
            return "Unknown"
        }
    }
    
    /// Get last 4 digits of card number
    func lastFourDigits() -> String {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        if cleaned.count >= 4 {
            return String(cleaned.suffix(4))
        }
        return ""
    }
}

struct OrderSummaryCheckout {
    var subtotal: Decimal = 0
    var shippingCost: Decimal = 0
    var tax: Decimal = 0
    var total: Decimal = 0
    
    /// Formatted subtotal currency string
    var formattedSubtotal: String { subtotal.toCurrentLocalePrice }
    
    /// Formatted shipping cost currency string or "Free" if 0
    var formattedShipping: String {
        shippingCost > 0 ? shippingCost.toCurrentLocalePrice : "Free"
    }
    
    /// Formatted tax currency string
    var formattedTax: String { tax.toCurrentLocalePrice }
    
    /// Formatted total currency string
    var formattedTotal: String { total.toCurrentLocalePrice }
    
    /// Initialize with default values
    init() {}
    
    /// Initialize with values
    init(subtotal: Decimal, shippingCost: Decimal, tax: Decimal) {
        self.subtotal = subtotal
        self.shippingCost = shippingCost
        self.tax = tax
        self.total = calculateTotal()
    }
    
    /// Initialize from cart
    init(cart: Cart) {
        self.subtotal = cart.totalAmount
        self.shippingCost = calculateShipping(subtotal)
        self.tax = calculateTax(subtotal)
        self.total = calculateTotal()
    }
    
    /// Calculate total by summing subtotal, shipping and tax
    private func calculateTotal() -> Decimal {
        return subtotal + shippingCost + tax
    }
    
    /// Calculate shipping cost based on order total
    private func calculateShipping(_ amount: Decimal) -> Decimal {
        // Free shipping for orders over $50, otherwise $5.99
        return amount > 50 ? 0 : Decimal(5.99)
    }
    
    /// Calculate tax based on subtotal
    private func calculateTax(_ amount: Decimal) -> Decimal {
        // Default tax rate: 8%
        return (amount * Decimal(0.08)).rounded(2)
    }
    
    /// Update values and recalculate total
    mutating func update(subtotal: Decimal) {
        self.subtotal = subtotal
        self.shippingCost = calculateShipping(subtotal)
        self.tax = calculateTax(subtotal)
        self.total = calculateTotal()
    }
}

class CheckoutViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var currentStep: CheckoutStep = .shippingInfo
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    @Published var shippingDetailsForm = ShippingDetailsForm()
    @Published var creditCardDetails = CreditCardDetails()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var cart: Cart?
    @Published var orderSummary = OrderSummaryCheckout()
    @Published var order: Order?
    @Published var paymentIntentId: String?
    @Published var clientSecret: String?
    @Published var showError = false
    @Published var cartItems: [CartItem] = []
    @Published var selectedAddress: Address?
    @Published var currentOrder: Order?
    @Published var paymentViewModel: PaymentViewModel
    
    // Shipping details related properties
    @Published var existingShippingDetails: ShippingDetailsResponse?
    @Published var hasExistingShippingDetails = false
    @Published var isEditingShippingDetails = false
    
    // Dependencies
    private let checkoutService: CheckoutServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    private let shippingService: ShippingServiceProtocol
    private let stripeService: StripeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var totalAmount: Double {
        cartItems.reduce(0) { $0 + (NSDecimalNumber(decimal: $1.product.price).doubleValue * Double($1.quantity)) }
    }
    
    // MARK: - Initialization
    
    init(
        cart: Cart?,
        checkoutService: CheckoutServiceProtocol,
        paymentService: PaymentServiceProtocol,
        authRepository: AuthRepositoryProtocol,
        validator: InputValidatorProtocol,
        shippingService: ShippingServiceProtocol,
        stripeService: StripeServiceProtocol
    ) {
        self.cart = cart
        self.checkoutService = checkoutService
        self.paymentService = paymentService
        self.authRepository = authRepository
        self.validator = validator
        self.shippingService = shippingService
        self.stripeService = stripeService
        self.paymentViewModel = PaymentViewModel(paymentService: paymentService, stripeService: stripeService)
        
        if let cart = cart {
            self.cartItems = cart.items
        }
        
        // Calculate order summary based on cart
        if let cart = cart {
            calculateOrderSummary(from: cart)
        }
        
        // Load existing shipping details if available
        loadExistingShippingDetails()
        loadUserAddress()
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
    
    func loadExistingShippingDetails() {
        guard let userId = getCurrentUserId() else { return }
        
        isLoading = true
        errorMessage = nil
        
        shippingService.getShippingDetails(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error loading shipping details: \(error)")
                    // Don't show error to user, just use blank form
                    self?.hasExistingShippingDetails = false
                    self?.isEditingShippingDetails = true
                }
            } receiveValue: { [weak self] details in
                guard let self = self else { return }
                
                if let details = details {
                    // Save existing details
                    self.existingShippingDetails = details
                    self.hasExistingShippingDetails = true
                    self.isEditingShippingDetails = false
                    
                    // Populate form with existing details
                    self.populateFormWithExistingDetails(details)
                    
                    Logger.info("Loaded existing shipping details for user")
                } else {
                    // No shipping details, show blank form
                    self.hasExistingShippingDetails = false
                    self.isEditingShippingDetails = true
                    Logger.info("No existing shipping details found, showing empty form")
                }
            }
            .store(in: &cancellables)
    }
    
    private func populateFormWithExistingDetails(_ details: ShippingDetailsResponse) {
        shippingDetailsForm.fullName = details.fullName ?? ""
        shippingDetailsForm.address = details.address
        shippingDetailsForm.city = details.city
        shippingDetailsForm.state = details.state ?? ""
        shippingDetailsForm.postalCode = details.postalCode
        shippingDetailsForm.country = details.country
        shippingDetailsForm.phoneNumber = details.phoneNumber ?? ""
        
        // Validate the form
        validateShippingForm()
    }
    
    /// Validate all shipping form fields
    /*
     func validateShippingForm() {
     let (isFullNameValid, fullNameError) = validateFullName(shippingDetailsForm.fullName)
     let (isAddressValid, addressError) = validateAddress(shippingDetailsForm.address)
     let (isCityValid, cityError) = validateCity(shippingDetailsForm.city)
     let (isStateValid, stateError) = validateState(shippingDetailsForm.state)
     let (isPostalCodeValid, postalCodeError) = validatePostalCode(shippingDetailsForm.postalCode)
     let (isCountryValid, countryError) = validateCountry(shippingDetailsForm.country)
     let (isPhoneNumberValid, phoneNumberError) = validatePhoneNumber(shippingDetailsForm.phoneNumber)
     
     shippingDetailsForm.isFullNameValid = isFullNameValid
     shippingDetailsForm.isAddressValid = isAddressValid
     shippingDetailsForm.isCityValid = isCityValid
     shippingDetailsForm.isStateValid = isStateValid
     shippingDetailsForm.isPostalCodeValid = isPostalCodeValid
     shippingDetailsForm.isCountryValid = isCountryValid
     shippingDetailsForm.isPhoneNumberValid = isPhoneNumberValid
     
     shippingDetailsForm.fullNameError = fullNameError
     shippingDetailsForm.addressError = addressError
     shippingDetailsForm.cityError = cityError
     shippingDetailsForm.stateError = stateError
     shippingDetailsForm.postalCodeError = postalCodeError
     shippingDetailsForm.countryError = countryError
     shippingDetailsForm.phoneNumberError = phoneNumberError
     }
     */
    
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
                
                // Update existing details
                self.existingShippingDetails = details
                self.hasExistingShippingDetails = true
                self.isEditingShippingDetails = false
                
                // Continue with checkout flow
                self.currentStep = .paymentMethod
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Order Creation
    
    func createOrder() -> Order? {
        guard let address = selectedAddress else {
            errorMessage = "Por favor, selecciona una dirección de envío"
            showError = true
            return nil
        }
        
        let orderItems = cartItems.map { item in
            OrderItem(
                id: nil,
                productId: item.product.id,
                productName: item.product.name,
                productBrand: item.product.brand,
                variantId: nil,
                variantName: nil,
                quantity: item.quantity,
                price: item.unitPrice,
                totalPrice: item.unitPrice * Decimal(item.quantity)
            )
        }
        
        let order = Order(
            id: Int.random(in: 1000...9999),
            userId: getCurrentUserId() ?? 0,
            orderDate: ISO8601DateFormatter().string(from: Date()),
            totalAmount: Decimal(calculateTotalAmount()),
            status: "pending",
            items: orderItems
        )
        
        currentOrder = order
        return order
    }
    
    // MARK: - Payment Processing
    
    func processPayment(orderId: Int) {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "No authenticated user"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.currentStep = .processing
        
        // Si es pago con tarjeta, crear primero el método de pago
        if selectedPaymentMethod == .creditCard {
            stripeService.createPaymentMethod(cardDetails: creditCardDetails)
                .catch { error -> AnyPublisher<String, Error> in
                    Logger.error("Error creating payment method: \(error)")
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                .flatMap { [weak self] paymentMethodId -> AnyPublisher<PaymentIntentResponse, Error> in
                    guard let self = self else {
                        return Fail(error: NSError(domain: "CheckoutViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                            .eraseToAnyPublisher()
                    }
                    
                    Logger.info("Payment method created successfully: \(paymentMethodId)")
                    
                    let paymentRequest = PaymentRequest(
                        paymentMethodId: paymentMethodId,
                        currency: "usd",
                        receiptEmail: nil,
                        description: "Payment for Order #\(orderId)"
                    )
                    
                    return self.paymentService.createPaymentIntent(orderId: orderId, request: paymentRequest)
                        .mapError { $0 as Error }
                        .eraseToAnyPublisher()
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    
                    if case .failure(let error) = completion {
                        self.isLoading = false
                        self.errorMessage = "Payment processing failed: \(error.localizedDescription)"
                        Logger.error("Error processing payment: \(error)")
                        self.currentStep = .error
                    }
                } receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    Logger.info("Payment intent created: \(response.paymentIntentId)")
                    
                    self.paymentIntentId = response.paymentIntentId
                    self.clientSecret = response.clientSecret
                    
                    // En una implementación real, aquí confirmarías el pago con Stripe SDK
                    // Para demos sin el SDK, simularemos el éxito después de un tiempo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isLoading = false
                        self.successMessage = "Payment processed successfully"
                        self.currentStep = .confirmation
                    }
                }
                .store(in: &cancellables)
        } else if selectedPaymentMethod == .applePay {
            // Simulación simple para Apple Pay en una demo
            Logger.info("Processing Apple Pay payment for order \(orderId)")
            
            // Simular procesamiento
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isLoading = false
                self.successMessage = "Apple Pay payment processed successfully"
                self.currentStep = .confirmation
            }
        } else {
            // Método de pago no soportado
            self.isLoading = false
            self.errorMessage = "Payment method not supported"
            self.currentStep = .error
        }
    }
    
    // Nuevo método para confirmar pagos con Stripe SDK
    private func confirmPaymentWithStripe(clientSecret: String) {
        // Aquí implementarías la confirmación del pago usando la interfaz de Stripe
        // Esto generalmente involucra mostrar una hoja de pago o interfaz 3D Secure
        // Ejemplo conceptual:
        
        // Nota: Esto es simplificado. En una implementación real,
        // usarías STPPaymentSheet o STPPaymentHandler para manejar la confirmación
        
        // Simulamos la confirmación para esta demostración
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            
            // Simular éxito para fines de demostración
            let success = true
            
            if success {
                self?.successMessage = "Payment processed successfully"
                self?.currentStep = .confirmation
            } else {
                self?.errorMessage = "Payment processing failed. Please try again."
                self?.currentStep = .error
            }
        }
    }
    
    private func generatePaymentMethodId(from cardDetails: CreditCardDetails) -> AnyPublisher<String, Error> {
        return stripeService.createPaymentMethod(cardDetails: creditCardDetails)
            .mapError { $0 as Error }
            .map { paymentMethodId -> String in
                Logger.info("Payment method created: \(paymentMethodId)")
                return paymentMethodId
            }
            .eraseToAnyPublisher()
    }
    
    func confirmPayment(paymentIntentId: String) {
        self.isLoading = true
        
        // In a real app, this would use Stripe SDK to handle 3D Secure, etc.
        // For this example, we'll simulate confirmation directly
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            
            // For demo purposes, simulate success most of the time
            let success = Int.random(in: 1...10) <= 9
            
            if success {
                self?.successMessage = "Payment processed successfully"
                self?.currentStep = .confirmation
            } else {
                self?.errorMessage = "Payment processing failed. Please try again."
                self?.currentStep = .error
            }
        }
    }
    
    // MARK: - Navigation
    
    func proceedToNextStep() {
        switch currentStep {
        case .shippingInfo:
            if selectedAddress != nil {
                currentStep = .paymentMethod
            } else {
                errorMessage = "Por favor, selecciona una dirección de envío"
                showError = true
            }
        case .paymentMethod:
            currentStep = .cardDetails
        case .cardDetails:
            currentStep = .review
        case .review:
            currentStep = .processing
        case .processing:
            currentStep = .confirmation
        case .confirmation, .error:
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
            currentStep = .cardDetails
        case .processing, .confirmation, .error, .shippingInfo:
            break
        }
    }
    
    // MARK: - Credit Card Validation
    /*
     func validateCardNumber(_ number: String) -> Bool {
     return validator.validateCreditCardNumber(number)
     }
     
     func validateExpiryDate(_ date: String) -> Bool {
     return validator.validateExpiryDate(date)
     }
     
     func validateCVV(_ cvv: String) -> Bool {
     return validator.validateCVV(cvv)
     }
     */
    
    func validateCardholderName(_ name: String) -> Bool {
        let result = validator.validateName(name)
        switch result {
        case .valid:
            return true
        case .invalid:
            return false
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
    
    private func loadUserAddress() {
        guard case let .loggedIn(user) = authRepository.authState.value else { return }
        
        isLoading = true
        shippingService.getShippingDetails(userId: user.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (completion: Subscribers.Completion<NetworkError>) in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            } receiveValue: { [weak self] (details: ShippingDetailsResponse?) in
                if let details = details {
                    // Convertir ShippingDetailsResponse a Address
                    let address = Address(
                        id: details.id,
                        userId: user.id,
                        street: details.address,
                        city: details.city,
                        state: details.state ?? "",
                        postalCode: details.postalCode,
                        country: details.country,
                        isDefault: true
                    )
                    self?.selectedAddress = address
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func calculateTotalAmount() -> Double {
        cartItems.reduce(0) { $0 + (NSDecimalNumber(decimal: $1.product.price).doubleValue * Double($1.quantity)) }
    }
    
    func getCurrentOrder() -> Order? {
        return currentOrder
    }
}

extension CheckoutViewModel {
    // MARK: - Credit Card Validation
    
    func validateCardNumber(_ number: String) -> (Bool, String?) {
        let result = validator.validateCreditCardNumber(number)
        switch result {
        case .valid:
            return (true, nil)
        case .invalid(let message):
            return (false, message)
        }
    }
    
    func validateExpiryDate(_ date: String) -> (Bool, String?) {
        let result = validator.validateExpiryDate(date)
        switch result {
        case .valid:
            return (true, nil)
        case .invalid(let message):
            return (false, message)
        }
    }
    
    func validateCVV(_ cvv: String) -> (Bool, String?) {
        let result = validator.validateCVV(cvv)
        switch result {
        case .valid:
            return (true, nil)
        case .invalid(let message):
            return (false, message)
        }
    }
    
    func validateCardholderName(_ name: String) -> (Bool, String?) {
        let result = validator.validateName(name)
        switch result {
        case .valid:
            return (true, nil)
        case .invalid(let message):
            return (false, message)
        }
    }
    
    // MARK: - Shipping Details Validation
    
    func validateShippingForm() {
        // Validar nombre completo
        let fullNameResult = validator.validateFullName(shippingDetailsForm.fullName)
        switch fullNameResult {
        case .valid:
            shippingDetailsForm.isFullNameValid = true
            shippingDetailsForm.fullNameError = nil
        case .invalid(let message):
            shippingDetailsForm.isFullNameValid = false
            shippingDetailsForm.fullNameError = message
        }
        
        // Validar dirección
        let addressResult = validator.validateName(shippingDetailsForm.address) // Usamos validateName por simplicidad
        switch addressResult {
        case .valid:
            shippingDetailsForm.isAddressValid = true
            shippingDetailsForm.addressError = nil
        case .invalid(let message):
            shippingDetailsForm.isAddressValid = false
            shippingDetailsForm.addressError = message
        }
        
        // Validar ciudad
        let cityResult = validator.validateName(shippingDetailsForm.city)
        switch cityResult {
        case .valid:
            shippingDetailsForm.isCityValid = true
            shippingDetailsForm.cityError = nil
        case .invalid(let message):
            shippingDetailsForm.isCityValid = false
            shippingDetailsForm.cityError = message
        }
        
        // Validar estado/provincia
        let stateResult = validator.validateName(shippingDetailsForm.state)
        switch stateResult {
        case .valid:
            shippingDetailsForm.isStateValid = true
            shippingDetailsForm.stateError = nil
        case .invalid(let message):
            shippingDetailsForm.isStateValid = false
            shippingDetailsForm.stateError = message
        }
        
        // Validar código postal
        let postalCodeResult = validator.validatePostalCode(shippingDetailsForm.postalCode)
        switch postalCodeResult {
        case .valid:
            shippingDetailsForm.isPostalCodeValid = true
            shippingDetailsForm.postalCodeError = nil
        case .invalid(let message):
            shippingDetailsForm.isPostalCodeValid = false
            shippingDetailsForm.postalCodeError = message
        }
        
        // Validar país
        let countryResult = validator.validateName(shippingDetailsForm.country)
        switch countryResult {
        case .valid:
            shippingDetailsForm.isCountryValid = true
            shippingDetailsForm.countryError = nil
        case .invalid(let message):
            shippingDetailsForm.isCountryValid = false
            shippingDetailsForm.countryError = message
        }
        
        // Validar teléfono
        let phoneResult = validator.validatePhoneNumber(shippingDetailsForm.phoneNumber)
        switch phoneResult {
        case .valid:
            shippingDetailsForm.isPhoneNumberValid = true
            shippingDetailsForm.phoneNumberError = nil
        case .invalid(let message):
            shippingDetailsForm.isPhoneNumberValid = false
            shippingDetailsForm.phoneNumberError = message
        }
    }
    
    func validateCreditCardForm() {
        // Validar número de tarjeta
        let cardNumberResult = validator.validateCreditCardNumber(creditCardDetails.cardNumber)
        switch cardNumberResult {
        case .valid:
            creditCardDetails.isCardNumberValid = true
            creditCardDetails.cardNumberError = nil
        case .invalid(let message):
            creditCardDetails.isCardNumberValid = false
            creditCardDetails.cardNumberError = message
        }
        
        // Validar nombre del titular
        let cardholderNameResult = validator.validateName(creditCardDetails.cardholderName)
        switch cardholderNameResult {
        case .valid:
            creditCardDetails.isCardholderNameValid = true
            creditCardDetails.cardholderNameError = nil
        case .invalid(let message):
            creditCardDetails.isCardholderNameValid = false
            creditCardDetails.cardholderNameError = message
        }
        
        // Validar fecha de expiración
        let expiryDateResult = validator.validateExpiryDate(creditCardDetails.expiryDate)
        switch expiryDateResult {
        case .valid:
            creditCardDetails.isExpiryDateValid = true
            creditCardDetails.expiryDateError = nil
        case .invalid(let message):
            creditCardDetails.isExpiryDateValid = false
            creditCardDetails.expiryDateError = message
        }
        
        // Validar CVV
        let cvvResult = validator.validateCVV(creditCardDetails.cvv)
        switch cvvResult {
        case .valid:
            creditCardDetails.isCvvValid = true
            creditCardDetails.cvvError = nil
        case .invalid(let message):
            creditCardDetails.isCvvValid = false
            creditCardDetails.cvvError = message
        }
    }
}
