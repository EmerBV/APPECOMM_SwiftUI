//
//  StripeService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

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
        Logger.info("StripeService: Stripe initialized with public key: \(config.publicKey)")
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
                        Logger.error("StripeService: Error creating payment method: \(error.localizedDescription)")
                        promise(.failure(.paymentMethodCreationFailed))
                        return
                    }
                    
                    guard let paymentMethod = paymentMethod else {
                        promise(.failure(.paymentMethodCreationFailed))
                        return
                    }
                    
                    Logger.info("StripeService: Payment method created: \(paymentMethod.stripeId)")
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
                    Logger.error("StripeService: Payment failed: \(error.localizedDescription)")
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
            guard let self = self, let apiClient = self.apiClient else {
                promise(.failure(.notConfigured))
                return
            }
            
            // Crear una llamada personalizada a la API para obtener un client secret
            // En lugar de usar métodos directos de STPAPIClient
            self.createPaymentIntentServerSide(
                amount: amount,
                currency: currency,
                customerId: customerId,
                apiClient: apiClient
            ) { result in
                switch result {
                case .success(let clientSecret):
                    promise(.success(clientSecret))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func createPaymentIntentServerSide(
        amount: Int,
        currency: String,
        customerId: String?,
        apiClient: STPAPIClient,
        completion: @escaping (Result<String, PaymentError>) -> Void
    ) {
        // Esta función simula una llamada al servidor para crear un PaymentIntent
        // En una aplicación real, harías una solicitud a tu propio servidor
        // que a su vez llamaría a la API de Stripe para crear un PaymentIntent
        
        // Ejemplo de URL de API del servidor
        guard let url = URL(string: "\(AppConfig.shared.apiBaseUrl)/payments/create-intent") else {
            completion(.failure(.invalidCardDetails))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Parámetros para el PaymentIntent
        var parameters: [String: Any] = [
            "amount": amount,
            "currency": currency.lowercased()
        ]
        
        if let customerId = customerId {
            parameters["customer"] = customerId
        }
        
        // Serializar parámetros
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(.paymentIntentCreationFailed))
            return
        }
        
        request.httpBody = httpBody
        
        // Realizar la solicitud
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.error("StripeService: Network error: \(error.localizedDescription)")
                completion(.failure(.paymentIntentCreationFailed))
                return
            }
            
            guard let data = data else {
                completion(.failure(.paymentIntentCreationFailed))
                return
            }
            
            // Analizar la respuesta
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let clientSecret = json["clientSecret"] as? String {
                    completion(.success(clientSecret))
                } else {
                    completion(.failure(.paymentIntentCreationFailed))
                }
            } catch {
                Logger.error("StripeService: JSON parsing error: \(error.localizedDescription)")
                completion(.failure(.paymentIntentCreationFailed))
            }
        }.resume()
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


