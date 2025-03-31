import Foundation
import Combine
import Stripe
import StripePaymentSheet
import UIKit

protocol StripeServiceProtocol {
    func initialize(with config: StripeConfig)
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, PaymentError>
    func handlePaymentResult(_ result: STPPaymentHandlerActionStatus, error: Error?) -> AnyPublisher<Bool, PaymentError>
    func checkoutWithPaymentSheet(amount: Int, currency: String, customerId: String?) -> AnyPublisher<String, PaymentError>
    func configurePaymentSheet(clientSecret: String, customerEphemeralKey: String?, customerId: String?) -> PaymentSheet?
    func isStripeInitialized() -> Bool
}

final class StripeService: StripeServiceProtocol {
    private var stripeConfig: StripeConfig?
    private var apiClient: STPAPIClient?
    
    init() {
        // No initialization needed here - done by initialize(with:)
    }
    
    func initialize(with config: StripeConfig) {
        self.stripeConfig = config
        StripeAPI.defaultPublishableKey = config.publicKey
        self.apiClient = STPAPIClient(publishableKey: config.publicKey)
        Logger.info("Stripe initialized with public key: \(config.publicKey)")
    }
    
    func isStripeInitialized() -> Bool {
        return stripeConfig != nil && apiClient != nil
    }
    
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, PaymentError> {
        return Future<String, PaymentError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.notConfigured))
                return
            }
            
            // Validar datos de la tarjeta
            do {
                let cardParams = try self.validateAndCreateCardParams(from: cardDetails)
                let billingDetails = self.createBillingDetails(from: cardDetails)
                
                // Crear parámetros para el método de pago
                let paymentMethodParams = STPPaymentMethodParams(
                    card: cardParams,
                    billingDetails: billingDetails,
                    metadata: nil
                )
                
                // Crear el método de pago con Stripe
                self.apiClient?.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                    if let error = error {
                        Logger.error("Error creating payment method: \(error.localizedDescription)")
                        promise(.failure(.paymentMethodCreationFailed))
                        return
                    }
                    
                    guard let paymentMethod = paymentMethod else {
                        promise(.failure(.paymentMethodCreationFailed))
                        return
                    }
                    
                    Logger.info("Payment method created: \(paymentMethod.stripeId)")
                    promise(.success(paymentMethod.stripeId))
                }
            } catch {
                if let paymentError = error as? PaymentError {
                    promise(.failure(paymentError))
                } else {
                    promise(.failure(.invalidCardDetails))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func validateAndCreateCardParams(from card: CreditCardDetails) throws -> STPPaymentMethodCardParams {
        // Verificar datos de la tarjeta
        if card.cardNumber.isEmpty {
            throw PaymentError.invalidCardDetails
        }
        
        if card.expiryDate.isEmpty {
            throw PaymentError.invalidExpiryDate
        }
        
        if card.cvv.isEmpty {
            throw PaymentError.invalidCardDetails
        }
        
        // Crear parámetros para la tarjeta
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = card.cardNumber.replacingOccurrences(of: " ", with: "")
        
        // Parsear fecha de expiración
        let expiryComponents = card.expiryDate.split(separator: "/")
        if expiryComponents.count == 2,
           let month = UInt(expiryComponents[0]),
           let year = UInt("20" + String(expiryComponents[1])) {
            cardParams.expMonth = NSNumber(value: month)
            cardParams.expYear = NSNumber(value: year)
        } else {
            throw PaymentError.invalidExpiryDate
        }
        
        cardParams.cvc = card.cvv
        return cardParams
    }
    
    private func createBillingDetails(from card: CreditCardDetails) -> STPPaymentMethodBillingDetails {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = card.cardholderName
        return billingDetails
    }
    
    func handlePaymentResult(_ result: STPPaymentHandlerActionStatus, error: Error?) -> AnyPublisher<Bool, PaymentError> {
        return Future<Bool, PaymentError> { promise in
            switch result {
            case .succeeded:
                promise(.success(true))
            case .failed:
                if let error = error {
                    Logger.error("Payment failed: \(error.localizedDescription)")
                    // Eliminar el argumento del parámetro clientSecret
                    promise(.failure(.paymentFailed))
                } else {
                    promise(.failure(.paymentFailed))
                }
            case .canceled:
                promise(.failure(.userCancelled))
            @unknown default:
                promise(.failure(.unknown))
            }
        }.eraseToAnyPublisher()
    }
    
    func checkoutWithPaymentSheet(amount: Int, currency: String, customerId: String?) -> AnyPublisher<String, PaymentError> {
        return Future<String, PaymentError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.notConfigured))
                return
            }
            
            // Crear el PaymentIntent
            let paymentIntentParams = STPPaymentIntentParams()
            paymentIntentParams.amount = amount
            paymentIntentParams.currency = currency.lowercased()
            
            if let customerId = customerId {
                paymentIntentParams.customer = customerId
            }
            
            self.apiClient?.createPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
                if let error = error {
                    // Eliminar el argumento del parámetro clientSecret
                    promise(.failure(.paymentFailed))
                    return
                }
                
                guard let clientSecret = paymentIntent?.clientSecret else {
                    // Eliminar el argumento del parámetro clientSecret
                    promise(.failure(.paymentFailed))
                    return
                }
                
                promise(.success(clientSecret))
            }
        }.eraseToAnyPublisher()
    }
    
    func configurePaymentSheet(clientSecret: String, customerEphemeralKey: String?, customerId: String?) -> PaymentSheet? {
        guard isStripeInitialized() else {
            return nil
        }
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "APPECOMM"
        
        // Configuración de cliente si está disponible
        if let ephemeralKey = customerEphemeralKey, let customerId = customerId {
            configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
        }
        
        // Configuración de apariencia
        configuration.appearance = configureAppearance()
        
        // Opciones de envío (opcional)
        configuration.shippingDetails = { return nil }
        
        // Opciones de pago
        configuration.allowsDelayedPaymentMethods = true
        
        return PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
    }
    
    private func configureAppearance() -> PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = UIColor.systemBlue
        appearance.colors.background = UIColor.systemBackground
        appearance.colors.componentBackground = UIColor.secondarySystemBackground
        appearance.colors.componentBorder = UIColor.separator
        return appearance
    }
}


