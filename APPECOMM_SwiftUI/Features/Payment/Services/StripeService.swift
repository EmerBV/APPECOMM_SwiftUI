import Foundation
import Combine
import Stripe

protocol StripeServiceProtocol {
    func initialize(with config: StripeConfig)
    func createPaymentMethod(card: STPPaymentMethodCardParams) -> AnyPublisher<String, PaymentError>
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, PaymentError>
    func handlePaymentResult(_ result: STPPaymentHandlerActionStatus, error: Error?) -> AnyPublisher<Bool, PaymentError>
}

final class StripeService: StripeServiceProtocol {
    private var stripeConfig: StripeConfig?
    
    func initialize(with config: StripeConfig) {
        self.stripeConfig = config
        StripeAPI.defaultPublishableKey = config.publicKey
        STPPaymentHandler.shared().apiClient = STPAPIClient(publishableKey: config.publicKey)
        Logger.info("Stripe initialized with public key: \(config.publicKey)")
    }
    
    func createPaymentMethod(card: STPPaymentMethodCardParams) -> AnyPublisher<String, PaymentError> {
        Future<String, PaymentError> { promise in
            let paymentMethodParams = STPPaymentMethodParams(
                card: card,
                billingDetails: nil,
                metadata: nil
            )
            
            STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                if let error = error {
                    promise(.failure(.paymentFailed(error.localizedDescription)))
                    return
                }
                
                guard let paymentMethodId = paymentMethod?.stripeId else {
                    promise(.failure(.invalidPaymentMethod))
                    return
                }
                
                promise(.success(paymentMethodId))
            }
        }.eraseToAnyPublisher()
    }
    
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, PaymentError> {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardDetails.cardNumber
        cardParams.expMonth = NSNumber(value: UInt(cardDetails.expiryDate.prefix(2)) ?? 0)
        cardParams.expYear = NSNumber(value: UInt(cardDetails.expiryDate.suffix(2)) ?? 0)
        cardParams.cvc = cardDetails.cvv
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = cardDetails.cardholderName
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )
        
        return Future<String, PaymentError> { promise in
            STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                if let error = error {
                    promise(.failure(.paymentFailed(error.localizedDescription)))
                    return
                }
                
                guard let paymentMethodId = paymentMethod?.stripeId else {
                    promise(.failure(.invalidPaymentMethod))
                    return
                }
                
                promise(.success(paymentMethodId))
            }
        }.eraseToAnyPublisher()
    }
    
    func handlePaymentResult(_ result: STPPaymentHandlerActionStatus, error: Error?) -> AnyPublisher<Bool, PaymentError> {
        Future<Bool, PaymentError> { promise in
            switch result {
            case .succeeded:
                promise(.success(true))
            case .failed:
                promise(.failure(.paymentFailed(error?.localizedDescription ?? "Error desconocido")))
            case .canceled:
                promise(.failure(.paymentFailed("Pago cancelado")))
            @unknown default:
                promise(.failure(.paymentFailed("Estado de pago desconocido")))
            }
        }.eraseToAnyPublisher()
    }
} 