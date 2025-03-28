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
    
    // Propiedades calculadas para el resumen de la orden
    @Published var subtotal: Decimal = 0
    @Published var shippingCost: Decimal = 0
    @Published var tax: Decimal = 0
    @Published var total: Decimal = 0
    
    // Dependencies
    private let paymentService: PaymentServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    private let cartRepository: CartRepositoryProtocol
    private let validator: InputValidatorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cart: Cart?,
        paymentService: PaymentServiceProtocol,
        authRepository: AuthRepositoryProtocol,
        cartRepository: CartRepositoryProtocol,
        validator: InputValidatorProtocol
    ) {
        self.cart = cart
        self.paymentService = paymentService
        self.authRepository = authRepository
        self.cartRepository = cartRepository
        self.validator = validator
        
        // Calcular los totales basados en el carrito
        if let cart = cart {
            calculateOrderSummary(from: cart)
        }
        
        // Cargar los detalles de envío del usuario si están disponibles
        loadUserShippingDetails()
    }
    
    private func loadUserShippingDetails() {
        // Si el usuario está autenticado, carga sus detalles de envío
        if case let .loggedIn(user) = authRepository.authState.value {
            if let userShippingDetails = user.shippingDetails {
                self.shippingDetails.address = userShippingDetails.address ?? ""
                self.shippingDetails.city = userShippingDetails.city ?? ""
                self.shippingDetails.postalCode = userShippingDetails.postalCode ?? ""
                self.shippingDetails.country = userShippingDetails.country ?? ""
                self.shippingDetails.phoneNumber = userShippingDetails.phoneNumber ?? ""
                
                // Marcar como válidos si hay datos
                self.shippingDetails.isAddressValid = !self.shippingDetails.address.isEmpty
                self.shippingDetails.isCityValid = !self.shippingDetails.city.isEmpty
                self.shippingDetails.isPostalCodeValid = !self.shippingDetails.postalCode.isEmpty
                self.shippingDetails.isCountryValid = !self.shippingDetails.country.isEmpty
                self.shippingDetails.isPhoneNumberValid = !self.shippingDetails.phoneNumber.isEmpty
            }
        }
    }
    
    private func calculateOrderSummary(from cart: Cart) {
        self.subtotal = cart.totalAmount
        
        // Calcular impuestos (ejemplo: 8% del subtotal)
        self.tax = calculateTax(subtotal)
        
        // Determinar costo de envío (gratis para más de $50)
        self.shippingCost = calculateShipping(subtotal)
        
        // Calcular total
        self.total = subtotal + tax + shippingCost
    }
    
    private func calculateTax(_ amount: Decimal) -> Decimal {
        // Ejemplo: 8% de impuestos
        return (amount * Decimal(0.08)).rounded(2)
    }
    
    private func calculateShipping(_ amount: Decimal) -> Decimal {
        // Envío gratis para compras mayores a $50, de lo contrario $5.99
        return amount > 50 ? 0 : Decimal(5.99)
    }
    
    // MARK: - Validación de datos
    
    func validateCardNumber(_ number: String) -> Bool {
        // Validación básica: 16 dígitos, empezando con prefijos comunes
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == 16, cleaned.allSatisfy({ $0.isNumber }) else {
            return false
        }
        
        // Verificar prefijos comunes (Visa, MC, Amex, Discover)
        let validPrefixes = ["4", "5", "3", "6"]
        return validPrefixes.contains(String(cleaned.prefix(1)))
    }
    
    func validateExpiryDate(_ date: String) -> Bool {
        // Formato debe ser MM/YY
        let components = date.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]),
              month >= 1, month <= 12 else {
            return false
        }
        
        // Verificar que la fecha sea en el futuro
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date()) % 100
        let currentMonth = calendar.component(.month, from: Date())
        
        return (year > currentYear) || (year == currentYear && month >= currentMonth)
    }
    
    func validateCVV(_ cvv: String) -> Bool {
        // Generalmente 3 o 4 dígitos
        let cleaned = cvv.replacingOccurrences(of: " ", with: "")
        return cleaned.count >= 3 && cleaned.count <= 4 && cleaned.allSatisfy({ $0.isNumber })
    }
    
    func validateCardholderName(_ name: String) -> Bool {
        // Al menos dos nombres, solo letras y espacios
        let names = name.split(separator: " ")
        return names.count >= 2 && name.allSatisfy({ $0.isLetter || $0.isWhitespace })
    }
    
    // MARK: - Procesamiento de Pagos
    
    func createPaymentIntent() {
        guard let cart = cart else {
            self.errorMessage = "No hay un carrito disponible"
            return
        }
        
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "No hay un usuario autenticado"
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
            
            // Avanzar al procesamiento del pago
            self?.simulatePaymentProcessing()
        }
    }
    
    private func simulatePaymentProcessing() {
        self.currentStep = .processing
        
        // Simular tiempo de procesamiento
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            // Para demostración, simulamos 90% de éxito
            let success = Int.random(in: 1...10) <= 9
            
            if success {
                self?.successMessage = "Pago procesado exitosamente"
                self?.currentStep = .confirmation
            } else {
                self?.errorMessage = "El procesamiento del pago falló. Por favor, intente de nuevo."
                self?.currentStep = .error
            }
            
            self?.isLoading = false
        }
    }
    
    // MARK: - Navegación
    
    func proceedToNextStep() {
        switch currentStep {
        case .shippingInfo:
            if validateShippingDetails() {
                currentStep = .paymentMethod
            } else {
                errorMessage = "Por favor complete toda la información de envío"
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
                errorMessage = "Por favor complete correctamente todos los datos de la tarjeta"
            }
            
        case .review:
            // Iniciar procesamiento del pago
            createPaymentIntent()
            
        case .processing:
            // Esperar a que termine el procesamiento
            break
            
        case .confirmation, .error:
            // Volver al carrito o a la pantalla principal
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
            // Para otros pasos, permanecer en el paso actual
            break
        }
    }
    
    private func validateShippingDetails() -> Bool {
        return shippingDetails.isAddressValid &&
               shippingDetails.isCityValid &&
               shippingDetails.isPostalCodeValid &&
               shippingDetails.isCountryValid &&
               shippingDetails.isPhoneNumberValid
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> Int? {
        if case let .loggedIn(user) = authRepository.authState.value {
            return user.id
        }
        return nil
    }
    
    // Formateo de tarjetas
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
    
    // Formateo de precios
    var formattedSubtotal: String {
        return subtotal.toCurrentLocalePrice
    }
    
    var formattedTax: String {
        return tax.toCurrentLocalePrice
    }
    
    var formattedShipping: String {
        return shippingCost > 0 ? shippingCost.toCurrentLocalePrice : "Gratis"
    }
    
    var formattedTotal: String {
        return total.toCurrentLocalePrice
    }
}

// Extensión de ShippingDetails para manejar la validación
extension ShippingDetails {
    var isAddressValid: Bool = false
    var isCityValid: Bool = false
    var isPostalCodeValid: Bool = false
    var isCountryValid: Bool = false
    var isPhoneNumberValid: Bool = false
    
    var isValid: Bool {
        return isAddressValid && isCityValid && isPostalCodeValid && isCountryValid && isPhoneNumberValid
    }
}
