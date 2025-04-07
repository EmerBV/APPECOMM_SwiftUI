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
    case review
    case processing
    case confirmation
    case error
}

enum PaymentMethodOptions: String, CaseIterable, Identifiable {
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
    @Published var selectedPaymentMethod: PaymentMethodOptions = .creditCard
    @Published var shippingDetailsForm = ShippingDetailsForm()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var cart: Cart?
    @Published var orderSummary = OrderSummaryCheckout()
    @Published var order: Order?
    @Published var showError = false
    @Published var cartItems: [CartItem] = []
    @Published var selectedAddress: ShippingDetails?
    @Published var currentOrder: Order?
    
    // Shipping details related properties
    @Published var existingShippingDetails: ShippingDetails?
    @Published var hasExistingShippingDetails = false
    @Published var isEditingShippingDetails = false
    
    @Published var shippingAddresses: [ShippingDetails] = [] // Lista de direcciones de envío
    @Published var selectedShippingAddressId: Int? // ID de la dirección seleccionada
    @Published var showingAddressSelector = false // Controla la visualización del selector de direcciones
    @Published var isAddingNewAddress = false // Controla si el usuario está agregando una nueva dirección
    
    // Payment specific properties
    @Published var paymentSheetViewModel: PaymentSheetViewModel?
    @Published var showPaymentSheet = false
    @Published var paymentViewModel: PaymentViewModel
    
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
        
        // Inicializar PaymentViewModel primero
        let dependencies = DependencyInjector.shared
        let stripeAPIClient = dependencies.resolve(StripeAPIClientProtocol.self)
        self.paymentViewModel = PaymentViewModel(
            paymentService: paymentService,
            stripeService: stripeService,
            stripeAPIClient: stripeAPIClient
        )
        
        // Una vez que todas las propiedades están inicializadas, podemos llamar a los métodos
        if let cartItems = cart?.items {
            self.cartItems = cartItems
        }
        
        // Configurar todo lo demás después de la inicialización
        self.setupInitialState()
    }
    
    private func setupInitialState() {
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
                } else if let order = self?.order {
                    // Si no hay orderId en la notificación, usar el ID de la orden actual
                    self?.handlePaymentSuccess(orderId: order.id)
                } else {
                    // Si no hay orden, mostrar un error
                    self?.handlePaymentFailure(message: "No se pudo procesar el pago: Orden no encontrada")
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("PaymentCancelled"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Restaurar el estado de la orden a "pending" o eliminarla si es apropiado
                if let orderId = self?.order?.id {
                    self?.updateOrderStatus(orderId: orderId, status: "cancelled")
                }
                
                // Actualizar la UI
                self?.isLoading = false
                self?.showPaymentSheet = false
                self?.currentStep = .review
                self?.errorMessage = "Pago cancelado. Puede intentarlo nuevamente."
                
                // Limpiar el PaymentSheetViewModel
                self?.paymentSheetViewModel = nil
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
    
    private func populateFormWithExistingDetails(_ details: ShippingDetails) {
        shippingDetailsForm.fullName = details.fullName ?? ""
        shippingDetailsForm.address = details.address ?? ""
        shippingDetailsForm.city = details.city ?? ""
        shippingDetailsForm.state = details.state ?? ""
        shippingDetailsForm.postalCode = details.postalCode ?? ""
        shippingDetailsForm.country = details.country ?? ""
        shippingDetailsForm.phoneNumber = details.phoneNumber ?? ""
        
        // Validate the form
        validateShippingForm()
    }
    
    func validateShippingForm() {
        // Validar todos los campos del formulario
        shippingDetailsForm.validateAll(validator: validator)
        
        // Validación explícita campo por campo para mayor control
        shippingDetailsForm.isFullNameValid = !shippingDetailsForm.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isFullNameValid {
            shippingDetailsForm.fullNameError = "Full name is required"
        }
        
        shippingDetailsForm.isAddressValid = !shippingDetailsForm.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isAddressValid {
            shippingDetailsForm.addressError = "Address is required"
        }
        
        shippingDetailsForm.isCityValid = !shippingDetailsForm.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isCityValid {
            shippingDetailsForm.cityError = "City is required"
        }
        
        shippingDetailsForm.isStateValid = !shippingDetailsForm.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isStateValid {
            shippingDetailsForm.stateError = "State is required"
        }
        
        shippingDetailsForm.isPostalCodeValid = !shippingDetailsForm.postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isPostalCodeValid {
            shippingDetailsForm.postalCodeError = "Postal code is required"
        }
        
        shippingDetailsForm.isCountryValid = !shippingDetailsForm.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isCountryValid {
            shippingDetailsForm.countryError = "Country is required"
        }
        
        shippingDetailsForm.isPhoneNumberValid = !shippingDetailsForm.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !shippingDetailsForm.isPhoneNumberValid {
            shippingDetailsForm.phoneNumberError = "Phone number is required"
        }
        
        // Loguear el resultado de la validación para debugging
        Logger.debug("Shipping form validation result: \(shippingDetailsForm.isValid)")
        if !shippingDetailsForm.isValid {
            Logger.debug("Form validation errors:")
            if !shippingDetailsForm.isFullNameValid { Logger.debug("- Full name: \(shippingDetailsForm.fullNameError ?? "invalid")") }
            if !shippingDetailsForm.isAddressValid { Logger.debug("- Address: \(shippingDetailsForm.addressError ?? "invalid")") }
            if !shippingDetailsForm.isCityValid { Logger.debug("- City: \(shippingDetailsForm.cityError ?? "invalid")") }
            if !shippingDetailsForm.isStateValid { Logger.debug("- State: \(shippingDetailsForm.stateError ?? "invalid")") }
            if !shippingDetailsForm.isPostalCodeValid { Logger.debug("- Postal code: \(shippingDetailsForm.postalCodeError ?? "invalid")") }
            if !shippingDetailsForm.isCountryValid { Logger.debug("- Country: \(shippingDetailsForm.countryError ?? "invalid")") }
            if !shippingDetailsForm.isPhoneNumberValid { Logger.debug("- Phone number: \(shippingDetailsForm.phoneNumberError ?? "invalid")") }
        }
    }
    
    func saveShippingDetails() {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "No authenticated user"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // Create shipping details request object from form
        // Si estamos editando una dirección existente, pasamos su ID
        let shippingDetailsRequest = ShippingDetailsRequest(
            id: isEditingShippingDetails ? existingShippingDetails?.id : nil,
            address: shippingDetailsForm.address,
            city: shippingDetailsForm.city,
            state: shippingDetailsForm.state,
            postalCode: shippingDetailsForm.postalCode,
            country: shippingDetailsForm.country,
            phoneNumber: shippingDetailsForm.phoneNumber,
            fullName: shippingDetailsForm.fullName,
            isDefault: true
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
                
                // Actualizar selectedAddress con los nuevos detalles
                let address = ShippingDetails(
                    id: details.id,
                    address: details.address,
                    city: details.city,
                    state: details.state ?? "",
                    postalCode: details.postalCode,
                    country: details.country,
                    phoneNumber: details.phoneNumber ?? "",
                    fullName: details.fullName,
                    isDefault: true
                )
                self.selectedAddress = address
                
                // Continue with checkout flow
                self.currentStep = .paymentMethod
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Order Creation
    func processPayment() {
        guard let selectedAddress = selectedAddress else {
            errorMessage = "Por favor, selecciona una dirección de envío"
            showError = true
            return
        }
        
        isLoading = true
        
        // First ensure we have a valid address ID
        guard let shippingDetailsId = selectedAddress.id else {
            isLoading = false
            errorMessage = "La dirección de envío no tiene un ID válido"
            showError = true
            return
        }
        
        guard let userId = getCurrentUserId() else {
            isLoading = false
            errorMessage = "No hay un usuario autenticado"
            showError = true
            return
        }
        
        // Create order with shipping details ID
        createOrderWithShippingDetails(userId: userId, shippingDetailsId: shippingDetailsId)
    }
    
    private func createOrderWithShippingDetails(userId: Int, shippingDetailsId: Int) {
        // Create the order with user ID and shipping details ID
        checkoutService.createOrder(userId: userId, shippingDetailsId: shippingDetailsId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    Logger.error("Failed to create order: \(error)")
                }
            } receiveValue: { [weak self] createdOrder in
                guard let self = self else { return }
                self.order = createdOrder
                
                // Once order is created, proceed with payment
                switch self.selectedPaymentMethod {
                case .creditCard:
                    self.prepareStripePayment(for: createdOrder)
                case .applePay:
                    self.processApplePayPayment(for: createdOrder)
                }
            }
            .store(in: &cancellables)
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
        
        // Asegurarse de que no haya un PaymentSheet anterior
        self.paymentSheetViewModel = nil
        self.showPaymentSheet = false
        
        // Asignar el nuevo PaymentSheetViewModel
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
                case .ready:
                    self?.isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.showPaymentSheet = true
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Prepare payment sheet
        paymentSheetVM.preparePaymentSheet()
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
    
    private func handlePaymentSuccess(orderId: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.showPaymentSheet = false
            self.currentStep = .confirmation
            self.successMessage = "¡Pago Completado!"
            
            // Limpiar el PaymentSheetViewModel
            self.paymentSheetViewModel = nil
            
            // Actualizar el estado de la orden
            self.updateOrderStatus(orderId: orderId, status: "paid")
        }
    }
    
    private func handlePaymentFailure(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.showPaymentSheet = false
            self.currentStep = .error
            self.errorMessage = message
            
            // Limpiar el PaymentSheetViewModel
            self.paymentSheetViewModel = nil
        }
    }
    
    private func updateOrderStatus(orderId: Int, status: String) {
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
    
    // MARK: - Navigation
    
    func proceedToNextStep() {
        switch currentStep {
        case .shippingInfo:
            validateShippingForm()
            if isAddingNewAddress {
                // Si estamos agregando una nueva dirección, llamar al método para crear
                if shippingDetailsForm.isValid {
                    createNewShippingAddress()
                } else {
                    errorMessage = "Por favor, completa todos los campos de envío correctamente"
                    showError = true
                }
            } else if let selectedAddress = selectedAddress {
                // Si ya hay una dirección seleccionada, podemos continuar sin guardar
                self.selectedShippingAddressId = selectedAddress.id
                currentStep = .paymentMethod
            } else if hasExistingShippingDetails && existingShippingDetails != nil {
                // Si tenemos detalles existentes pero no hay dirección seleccionada, utilizamos esos
                self.selectedAddress = existingShippingDetails
                currentStep = .paymentMethod
            } else if shippingDetailsForm.isValid {
                // De lo contrario, si el formulario es válido, guardamos los detalles
                saveShippingDetails()
            } else {
                errorMessage = "Por favor, completa todos los campos de envío correctamente o selecciona una dirección"
                showError = true
            }
        case .paymentMethod:
            // Asegurarse de que hay una dirección seleccionada
            if selectedAddress == nil {
                if let existingDetails = existingShippingDetails {
                    selectedAddress = existingDetails
                } else if !shippingAddresses.isEmpty {
                    // Si no hay dirección seleccionada pero hay direcciones disponibles,
                    // seleccionar la predeterminada o la primera
                    if let defaultAddress = shippingAddresses.first(where: { $0.isDefault ?? false }) {
                        selectedAddress = defaultAddress
                        selectedShippingAddressId = defaultAddress.id
                    } else {
                        selectedAddress = shippingAddresses.first
                        selectedShippingAddressId = shippingAddresses.first?.id
                    }
                } else {
                    errorMessage = "Por favor, selecciona una dirección de envío"
                    showError = true
                    return
                }
            }
            currentStep = .review
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
        case .review:
            currentStep = .paymentMethod
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
    
    // MARK: - Public Methods
    
    func calculateTotalAmount() -> Double {
        cartItems.reduce(0) { $0 + (NSDecimalNumber(decimal: $1.product.price).doubleValue * Double($1.quantity)) }
    }
    
    func getCurrentOrder() -> Order? {
        return currentOrder
    }
    
    // Cargar todas las direcciones de envío del usuario actual
    func loadShippingAddresses() {
        guard let userId = getCurrentUserId() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.getAllShippingAddresses(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error loading shipping addresses: \(error)")
                    self?.errorMessage = "Failed to load shipping addresses: \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] addresses in
                guard let self = self else { return }
                
                // Convertir ShippingDetailsResponse a ShippingDetails
                self.shippingAddresses = addresses.map { response in
                    ShippingDetails(
                        id: response.id,
                        address: response.address,
                        city: response.city,
                        state: response.state ?? "",
                        postalCode: response.postalCode,
                        country: response.country,
                        phoneNumber: response.phoneNumber ?? "",
                        fullName: response.fullName ?? "",
                        isDefault: response.isDefault ?? false
                    )
                }
                
                // Si no hay dirección seleccionada, seleccionar la predeterminada
                if self.selectedShippingAddressId == nil {
                    if let defaultAddress = self.shippingAddresses.first(where: { $0.isDefault ?? false }) {
                        self.selectedShippingAddressId = defaultAddress.id
                        self.selectedAddress = defaultAddress
                    } else if !self.shippingAddresses.isEmpty {
                        // Si no hay predeterminada, seleccionar la primera
                        self.selectedShippingAddressId = self.shippingAddresses.first?.id
                        self.selectedAddress = self.shippingAddresses.first
                    } else {
                        // No hay direcciones, mostrar formulario para agregar
                        self.isAddingNewAddress = true
                    }
                }
                
                Logger.info("Loaded \(self.shippingAddresses.count) shipping addresses")
            }
            .store(in: &cancellables)
    }
    
    // Seleccionar una dirección de envío
    func selectShippingAddress(id: Int) {
        guard let address = shippingAddresses.first(where: { $0.id == id }) else {
            Logger.error("Selected address not found: \(id)")
            return
        }
        
        selectedShippingAddressId = id
        selectedAddress = address
        showingAddressSelector = false
        
        Logger.info("Selected shipping address: \(id)")
    }
    
    // Crear una nueva dirección de envío
    func createNewShippingAddress() {
        guard let userId = getCurrentUserId() else {
            errorMessage = "No user ID available"
            showError = true
            return
        }
        
        validateShippingForm()
        if !shippingDetailsForm.isValid {
            errorMessage = "Please fill in all required fields correctly"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        // Crear la nueva dirección - Asegúrate de que el ID sea nil para crear una nueva
        var newAddress = ShippingDetailsForm()
        newAddress.fullName = shippingDetailsForm.fullName
        newAddress.address = shippingDetailsForm.address
        newAddress.city = shippingDetailsForm.city
        newAddress.state = shippingDetailsForm.state
        newAddress.postalCode = shippingDetailsForm.postalCode
        newAddress.country = shippingDetailsForm.country
        newAddress.phoneNumber = shippingDetailsForm.phoneNumber
        newAddress.isDefaultAddress = shippingDetailsForm.isDefaultAddress
        
        // Validar nuevamente para asegurarnos
        newAddress.validateAll()
        
        if !newAddress.isValid {
            isLoading = false
            errorMessage = "Please fill in all required fields correctly"
            showError = true
            return
        }
        
        // Crear la nueva dirección
        shippingRepository.createShippingAddress(userId: userId, details: newAddress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error creating shipping address: \(error)")
                    self?.errorMessage = "Failed to create shipping address: \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] newAddress in
                guard let self = self else { return }
                
                // Crear un objeto ShippingDetails a partir de la respuesta
                let address = ShippingDetails(
                    id: newAddress.id,
                    address: newAddress.address,
                    city: newAddress.city,
                    state: newAddress.state ?? "",
                    postalCode: newAddress.postalCode,
                    country: newAddress.country,
                    phoneNumber: newAddress.phoneNumber ?? "",
                    fullName: newAddress.fullName ?? "",
                    isDefault: newAddress.isDefault ?? false
                )
                
                // Agregar la nueva dirección a la lista y seleccionarla
                self.shippingAddresses.append(address)
                self.selectedShippingAddressId = address.id
                self.selectedAddress = address
                
                // Salir del modo de agregar dirección
                self.isAddingNewAddress = false
                
                // Continuar con el proceso de checkout
                self.currentStep = .paymentMethod
                
                Logger.info("Created new shipping address with ID: \(address.id ?? 0)")
            }
            .store(in: &cancellables)
    }
    
    // Establecer una dirección como predeterminada
    func setAddressAsDefault(id: Int) {
        guard let userId = getCurrentUserId() else {
            errorMessage = "No user ID available"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.setDefaultShippingAddress(userId: userId, addressId: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error setting default address: \(error)")
                    self?.errorMessage = "Failed to set default address: \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] defaultAddress in
                guard let self = self else { return }
                
                // Actualizar las banderas isDefault en todas las direcciones
                self.shippingAddresses = self.shippingAddresses.map { address in
                    ShippingDetails(
                        id: address.id,
                        address: address.address,
                        city: address.city,
                        state: address.state,
                        postalCode: address.postalCode,
                        country: address.country,
                        phoneNumber: address.phoneNumber,
                        fullName: address.fullName,
                        isDefault: (address.id == id)
                    )
                }
                
                Logger.info("Set address \(id) as default")
            }
            .store(in: &cancellables)
    }
    
    // Eliminar una dirección de envío
    func deleteShippingAddress(id: Int) {
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.deleteShippingAddress(userId: getCurrentUserId() ?? 0, addressId: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error deleting address: \(error)")
                    self?.errorMessage = "Failed to delete address: \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                
                // Eliminar la dirección de la lista
                self.shippingAddresses.removeAll { $0.id == id }
                
                // Si se eliminó la dirección seleccionada, seleccionar otra
                if self.selectedShippingAddressId == id {
                    if let defaultAddress = self.shippingAddresses.first(where: { $0.isDefault ?? false }) {
                        self.selectedShippingAddressId = defaultAddress.id
                        self.selectedAddress = defaultAddress
                    } else if !self.shippingAddresses.isEmpty {
                        self.selectedShippingAddressId = self.shippingAddresses.first?.id
                        self.selectedAddress = self.shippingAddresses.first
                    } else {
                        self.selectedShippingAddressId = nil
                        self.selectedAddress = nil
                        self.isAddingNewAddress = true
                    }
                }
                
                Logger.info("Deleted shipping address \(id)")
            }
            .store(in: &cancellables)
    }
    
    // Sobrescribir el método loadUserAddress para usar el nuevo sistema de múltiples direcciones
    private func loadUserAddress() {
        guard case let .loggedIn(user) = authRepository.authState.value else { return }
        
        // Cargar todas las direcciones y seleccionar la predeterminada
        loadShippingAddresses()
    }
    
    private func createShippingDetailsRequest() -> ShippingDetailsRequest {
        // Este es un método mejorado para crear una solicitud de detalles de envío
        // con un manejo más robusto del ID
        
        if isEditingShippingDetails {
            // Si estamos editando una dirección existente, usamos su ID
            return ShippingDetailsRequest(
                id: existingShippingDetails?.id,
                address: shippingDetailsForm.address,
                city: shippingDetailsForm.city,
                state: shippingDetailsForm.state,
                postalCode: shippingDetailsForm.postalCode,
                country: shippingDetailsForm.country,
                phoneNumber: shippingDetailsForm.phoneNumber,
                fullName: shippingDetailsForm.fullName,
                isDefault: shippingDetailsForm.isDefaultAddress ?? false
            )
        } else if let selectedAddr = selectedAddress {
            // Si ya hay una dirección seleccionada, usamos ese ID
            return ShippingDetailsRequest(
                id: selectedAddr.id,
                address: selectedAddr.address ?? "",
                city: selectedAddr.city ?? "",
                state: selectedAddr.state ?? "",
                postalCode: selectedAddr.postalCode ?? "",
                country: selectedAddr.country ?? "",
                phoneNumber: selectedAddr.phoneNumber ?? "",
                fullName: selectedAddr.fullName ?? "",
                isDefault: selectedAddr.isDefault ?? false
            )
        } else {
            // Si estamos creando una nueva dirección, el ID debe ser nil
            return ShippingDetailsRequest(
                id: nil,
                address: shippingDetailsForm.address,
                city: shippingDetailsForm.city,
                state: shippingDetailsForm.state,
                postalCode: shippingDetailsForm.postalCode,
                country: shippingDetailsForm.country,
                phoneNumber: shippingDetailsForm.phoneNumber,
                fullName: shippingDetailsForm.fullName,
                isDefault: shippingDetailsForm.isDefaultAddress ?? false
            )
        }
    }
    
    private func updateDefaultAddress(_ address: ShippingDetails) {
        // En lugar de modificar la dirección existente, creamos una nueva
        let updatedAddress = ShippingDetails(
            id: address.id,
            address: address.address,
            city: address.city,
            state: address.state,
            postalCode: address.postalCode,
            country: address.country,
            phoneNumber: address.phoneNumber,
            fullName: address.fullName,
            isDefault: true
        )
        selectedAddress = updatedAddress
    }
    
    private func validatePaymentMethod() -> Bool {
        guard let isDefault = selectedAddress?.isDefault else {
            errorMessage = "Seleccione una dirección de envío"
            return false
        }
        return isDefault
    }
    
    // Método auxiliar para garantizar que siempre haya una dirección seleccionada
    func ensureShippingAddressSelected() {
        // Si no hay dirección seleccionada pero hay una predeterminada,
        // seleccionamos automáticamente la predeterminada
        if selectedAddress == nil {
            if let defaultAddress = shippingAddresses.first(where: { $0.isDefault ?? false }) {
                selectedAddress = defaultAddress
                selectedShippingAddressId = defaultAddress.id
            } else if !shippingAddresses.isEmpty {
                // Si no hay dirección predeterminada, seleccionamos la primera
                selectedAddress = shippingAddresses.first
                selectedShippingAddressId = shippingAddresses.first?.id
            } else if existingShippingDetails != nil {
                // Si no hay direcciones pero hay detalles existentes, los usamos
                selectedAddress = existingShippingDetails
            }
        }
    }
    
    // Método para actualizar una dirección existente
    func updateExistingShippingAddress() {
        guard let userId = getCurrentUserId() else {
            errorMessage = "No user ID available"
            showError = true
            return
        }
        
        guard let addressId = selectedAddress?.id else {
            errorMessage = "No address ID available for update"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Crear request con el ID correcto
        let request = ShippingDetailsRequest(
            id: addressId,
            address: shippingDetailsForm.address,
            city: shippingDetailsForm.city,
            state: shippingDetailsForm.state,
            postalCode: shippingDetailsForm.postalCode,
            country: shippingDetailsForm.country,
            phoneNumber: shippingDetailsForm.phoneNumber,
            fullName: shippingDetailsForm.fullName,
            isDefault: shippingDetailsForm.isDefaultAddress ?? false
        )
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.updateShippingAddress(userId: userId, details: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error updating shipping address: \(error)")
                    self?.errorMessage = "Failed to update shipping address: \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] updatedAddress in
                guard let self = self else { return }
                
                // Actualizar la dirección seleccionada
                let address = ShippingDetails(
                    id: updatedAddress.id,
                    address: updatedAddress.address,
                    city: updatedAddress.city,
                    state: updatedAddress.state ?? "",
                    postalCode: updatedAddress.postalCode,
                    country: updatedAddress.country,
                    phoneNumber: updatedAddress.phoneNumber ?? "",
                    fullName: updatedAddress.fullName ?? "",
                    isDefault: updatedAddress.isDefault ?? false
                )
                
                self.selectedAddress = address
                self.selectedShippingAddressId = address.id
                
                // Actualizar la lista de direcciones
                if let index = self.shippingAddresses.firstIndex(where: { $0.id == address.id }) {
                    self.shippingAddresses[index] = address
                }
                
                // Continuar con el proceso de checkout
                self.currentStep = .paymentMethod
                
                Logger.info("Updated shipping address with ID: \(address.id ?? 0)")
            }
            .store(in: &cancellables)
    }
    
    /// Restablece el estado del checkout para cuando el usuario cancela el proceso
    func resetCheckoutState() {
        // Restablecer el estado del flujo de checkout
        currentStep = .shippingInfo
        
        // Limpiar mensajes de error o éxito
        errorMessage = nil
        successMessage = nil
        
        // Restablecer formularios si es necesario
        if !hasExistingShippingDetails {
            shippingDetailsForm = ShippingDetailsForm()
        }
        
        // Limpiar selecciones
        isAddingNewAddress = false
        
        // Cancelar cualquier operación en progreso
        isLoading = false
        
        // Limpiar estado de pago
        showPaymentSheet = false
        paymentSheetViewModel = nil
        
        // Si hay una orden en proceso, consideremos cancelarla en el backend
        if let orderId = order?.id {
            updateOrderStatus(orderId: orderId, status: "cancelled")
            order = nil
        }
        
        Logger.info("Checkout state reset due to user cancellation")
    }
    
}
