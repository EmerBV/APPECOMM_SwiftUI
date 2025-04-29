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
            return "credit_card_option".localized
        case .applePay:
            return "apple_pay_option".localized
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
    
    // Shipping details related properties
    @Published var existingShippingDetails: ShippingDetails?
    @Published var hasExistingShippingDetails = false
    @Published var isEditingShippingDetails = false
    
    @Published var shippingAddresses: [ShippingDetails] = []
    @Published var selectedShippingAddressId: Int?
    @Published var showingAddressSelector = false
    @Published var isAddingNewAddress = false
    
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
    private let shippingRepository: ShippingRepositoryProtocol
    private let dependencyInjector: DependencyInjector
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        cart: Cart?,
        checkoutService: CheckoutServiceProtocol,
        paymentService: PaymentServiceProtocol,
        authRepository: AuthRepositoryProtocol,
        validator: InputValidatorProtocol,
        shippingService: ShippingServiceProtocol,
        stripeService: StripeServiceProtocol,
        shippingRepository: ShippingRepositoryProtocol,
        dependencyInjector: DependencyInjector = DependencyInjector.shared
    ) {
        self.cart = cart
        self.checkoutService = checkoutService
        self.paymentService = paymentService
        self.authRepository = authRepository
        self.validator = validator
        self.shippingService = shippingService
        self.stripeService = stripeService
        self.shippingRepository = shippingRepository
        self.dependencyInjector = dependencyInjector
        
        if let cartItems = cart?.items {
            self.cartItems = cartItems
        }
        
        // Configurar todo lo demás después de la inicialización
        setupInitialState()
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
                    self?.handlePaymentFailure(message: "checkout_payment_failure".localized)
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
                self?.errorMessage = "payment_cancelled".localized
                
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
        
        shippingRepository.getDefaultShippingAddress(userId: userId)
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
        
        // Loguear el resultado de la validación para debugging
        Logger.debug("Shipping form validation result: \(shippingDetailsForm.isValid)")
        if !shippingDetailsForm.isValid {
            let invalidFields = [
                (!shippingDetailsForm.isFullNameValid, "full name"),
                (!shippingDetailsForm.isAddressValid, "address"),
                (!shippingDetailsForm.isCityValid, "city"),
                (!shippingDetailsForm.isStateValid, "state"),
                (!shippingDetailsForm.isPostalCodeValid, "postal code"),
                (!shippingDetailsForm.isCountryValid, "country"),
                (!shippingDetailsForm.isPhoneNumberValid, "phone number")
            ].filter { $0.0 }.map { $0.1 }
            
            Logger.debug("Invalid fields: \(invalidFields.joined(separator: ", "))")
        }
    }
    
    func saveShippingDetails() {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "no_authenticated_user".localized
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
        
        // Call repository to save shipping details
        shippingRepository.updateShippingAddress(userId: userId, details: shippingDetailsRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "failed_to_save_shipping_details".localized + ": \(error.localizedDescription)"
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
    
    // MARK: - Order Creation and Payment Processing
    
    func processPayment() {
        guard let selectedAddress = selectedAddress else {
            errorMessage = "please_select_shipping_address".localized
            showError = true
            return
        }
        
        isLoading = true
        
        // First ensure we have a valid address ID
        guard let shippingDetailsId = selectedAddress.id else {
            isLoading = false
            errorMessage = "invalid_shipping_address_id".localized
            showError = true
            return
        }
        
        guard let userId = getCurrentUserId() else {
            isLoading = false
            errorMessage = "no_authenticated_user".localized
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
        
        // Create PaymentSheetViewModel using DI
        let email = getCurrentUserEmail()
        let paymentSheetVM = dependencyInjector.resolve(
            PaymentSheetViewModel.self,
            arguments: order.id, order.totalAmount, email
        )
        
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
            self.successMessage = "payment_completed".localized
            
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
                    errorMessage = "please_complete_shipping_fields".localized
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
                errorMessage = "please_complete_shipping_fields_or_select_address".localized
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
                    errorMessage = "please_select_shipping_address".localized
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
    
    // MARK: - Address Management
    
    // Cargar todas las direcciones de envío del usuario actual
    func loadUserAddress() {
        guard let userId = getCurrentUserId() else { return }
        
        isLoading = true
        errorMessage = nil
        
        shippingRepository.getAllShippingAddresses(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error loading shipping addresses: \(error)")
                    self?.errorMessage = "failed_to_load_shipping_addresses".localized + ": \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] addresses in
                guard let self = self else { return }
                
                self.shippingAddresses = addresses
                
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
            errorMessage = "no_user_id_available".localized
            showError = true
            return
        }
        
        validateShippingForm()
        if !shippingDetailsForm.isValid {
            errorMessage = "please_fill_required_fields".localized
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Crear la nueva dirección
        shippingRepository.createShippingAddress(userId: userId, details: shippingDetailsForm)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error creating shipping address: \(error)")
                    self?.errorMessage = "failed_to_create_shipping_address".localized + ": \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] newAddress in
                guard let self = self else { return }
                
                // Agregar la nueva dirección a la lista y seleccionarla
                self.shippingAddresses.append(newAddress)
                self.selectedShippingAddressId = newAddress.id
                self.selectedAddress = newAddress
                
                // Salir del modo de agregar dirección
                self.isAddingNewAddress = false
                
                // Continuar con el proceso de checkout
                self.currentStep = .paymentMethod
                
                Logger.info("Created new shipping address with ID: \(newAddress.id ?? 0)")
            }
            .store(in: &cancellables)
    }
    
    // Establecer una dirección como predeterminada
    func setAddressAsDefault(id: Int) {
        guard let userId = getCurrentUserId() else {
            errorMessage = "no_user_id_available".localized
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        shippingRepository.setDefaultShippingAddress(userId: userId, addressId: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error setting default address: \(error)")
                    self?.errorMessage = "failed_to_set_default_address".localized + ": \(error.localizedDescription)"
                    self?.showError = true
                }
            } receiveValue: { [weak self] defaultAddress in
                guard let self = self else { return }
                
                // Actualizar las banderas isDefault en todas las direcciones
                self.shippingAddresses = self.shippingAddresses.map { address in
                    var updatedAddress = address
                    if address.id == id {
                        updatedAddress = ShippingDetails(
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
                    } else if address.isDefault == true {
                        updatedAddress = ShippingDetails(
                            id: address.id,
                            address: address.address,
                            city: address.city,
                            state: address.state,
                            postalCode: address.postalCode,
                            country: address.country,
                            phoneNumber: address.phoneNumber,
                            fullName: address.fullName,
                            isDefault: false
                        )
                    }
                    return updatedAddress
                }
                
                Logger.info("Set address \(id) as default")
            }
            .store(in: &cancellables)
    }
    
    // Eliminar una dirección de envío
    func deleteShippingAddress(id: Int) {
        isLoading = true
        errorMessage = nil
        
        shippingRepository.deleteShippingAddress(userId: getCurrentUserId() ?? 0, addressId: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error deleting address: \(error)")
                    self?.errorMessage = "failed_to_delete_address".localized + ": \(error.localizedDescription)"
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
    
    // Método para garantizar que siempre haya una dirección seleccionada
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
