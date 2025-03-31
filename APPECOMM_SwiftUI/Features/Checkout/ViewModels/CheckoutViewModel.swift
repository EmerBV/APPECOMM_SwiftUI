//
//  CheckoutViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine
import SwiftUI
import Stripe

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
    @Published var showError = false
    @Published var cartItems: [CartItem] = []
    @Published var selectedAddress: Address?
    @Published var currentOrder: Order?
    
    // Shipping details related properties
    @Published var existingShippingDetails: ShippingDetailsResponse?
    @Published var hasExistingShippingDetails = false
    @Published var isEditingShippingDetails = false
    
    // Payment specific properties
    @Published var paymentSheetViewModel: PaymentSheetViewModel?
    @Published var showPaymentSheet = false
    
    // Dependencies
    private let checkoutService: CheckoutServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    private let validator: InputValidatorProtocol
    private let shippingService: ShippingServiceProtocol
    private let stripeService: StripeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // Configurar notificaciones para resultados de pago
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: Notification.Name("PaymentCompleted"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let orderId = notification.userInfo?["orderId"] as? Int {
                    self?.handlePaymentSuccess(orderId: orderId)
                } else {
                    self?.handlePaymentSuccess()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Order Summary Calculation
    
    private func calculateOrderSummary(from cart: Cart) {
        self.orderSummary.subtotal = cart.totalAmount
           
           // Calculate tax (example: 8% of subtotal)
           self.orderSummary.tax = calculateTax(orderSummary.subtotal)
           
           // Determine shipping cost (free for orders over $50)
           self.orderSummary.shippingCost = calculateShipping(orderSummary.subtotal)
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
    
    func validateShippingForm() {
        // Validar todos los campos del formulario
        shippingDetailsForm.validateAll(validator: validator)
    }
    
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
    
    func processPayment() {
        if let order = createOrder() {
            self.order = order
            
            switch selectedPaymentMethod {
            case .creditCard:
                prepareStripePayment(for: order)
            case .applePay:
                processApplePayPayment(for: order)
            }
        }
    }
    
    private func prepareStripePayment(for order: Order) {
        isLoading = true
        currentStep = .processing
        
        // Create PaymentSheetViewModel
        let email = getCurrentUserEmail()
        let paymentSheetVM = PaymentSheetViewModel(
            paymentService: paymentService,
            orderId: order.id,
            amount: order.totalAmount,
            email: email
        )
        
        self.paymentSheetViewModel = paymentSheetVM
        
        // Observe changes in payment status
        paymentSheetVM.$paymentStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .completed:
                    self?.handlePaymentSuccess(orderId: order.id)
                case .failed(let message):
                    self?.handlePaymentFailure(message: message)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Prepare payment sheet
        paymentSheetVM.preparePaymentSheet()
        
        // Show payment sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.showPaymentSheet = true
        }
    }
    
    private func processApplePayPayment(for order: Order) {
        // Implementación de Apple Pay
        // En un caso real, usarías PKPaymentRequest y el framework de Apple Pay
        
        // Esta es una simulación
        isLoading = true
        currentStep = .processing
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            self?.handlePaymentSuccess(orderId: order.id)
        }
    }
    
    func handlePaymentSuccess(orderId: Int = 0) {
        isLoading = false
        currentStep = .confirmation
        successMessage = "Payment processed successfully"
        
        // Si tenemos un orderId, actualizar el estado del pedido
        if orderId > 0 {
            // Actualizar estado de la orden
            updateOrderStatus(orderId: orderId, status: "paid")
        }
    }
    
    func handlePaymentFailure(message: String) {
        isLoading = false
        errorMessage = message
        currentStep = .error
    }
    
    private func updateOrderStatus(orderId: Int, status: String) {
        // Actualizar el estado de la orden en el servidor
        checkoutService.updateOrderStatus(id: orderId, status: status)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to update order status: \(error)")
                }
            } receiveValue: { [weak self] updatedOrder in
                self?.order = updatedOrder
                Logger.info("Order status updated to: \(status)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Credit Card Validation
    
    func validateCreditCardForm() {
        creditCardDetails.validateAll(validator: validator)
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
            if selectedPaymentMethod == .creditCard {
                currentStep = .cardDetails
            } else {
                currentStep = .review
            }
        case .cardDetails:
            validateCreditCardForm()
            if creditCardDetails.isValid {
                currentStep = .review
            }
        case .review:
            processPayment()
        case .processing:
            // Waiting for payment processing to complete
            break
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
            if selectedPaymentMethod == .creditCard {
                currentStep = .cardDetails
            } else {
                currentStep = .paymentMethod
            }
        case .processing, .confirmation, .error, .shippingInfo:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    func getCurrentUserId() -> Int? {
        if case let .loggedIn(user) = authRepository.authState.value {
            return user.id
        }
        return nil
    }
    
    func getCurrentUserEmail() -> String? {
        if case let .loggedIn(user) = authRepository.authState.value {
            return user.email
        }
        return nil
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
