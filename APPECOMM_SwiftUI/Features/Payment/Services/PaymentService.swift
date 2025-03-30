import Foundation
import Combine

protocol PaymentServiceProtocol {
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError>
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError>
}

final class PaymentService: PaymentServiceProtocol {
    private let networkDispatcher: NetworkDispatcher
    private let stripeService: StripeServiceProtocol
    
    init(networkDispatcher: NetworkDispatcher = NetworkDispatcher(),
         stripeService: StripeServiceProtocol = StripeService()) {
        self.networkDispatcher = networkDispatcher
        self.stripeService = stripeService
    }
    
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError> {
        let endpoint = PaymentEndpoints.getStripeConfig
        Logger.info("Obteniendo configuración de Stripe")
        
        return networkDispatcher.dispatch(ApiResponse<StripeConfig>.self, endpoint)
            .map { response -> StripeConfig in
                Logger.info("Configuración de Stripe obtenida exitosamente")
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError> {
        let endpoint = PaymentEndpoints.createPaymentIntent(orderId: orderId, request: request)
        Logger.info("Creando intención de pago para orden ID: \(orderId)")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentIntentResponse>.self, endpoint)
            .map { response -> PaymentIntentResponse in
                Logger.info("Intención de pago creada exitosamente: \(response.data.paymentIntentId)")
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        let endpoint = PaymentEndpoints.confirmPayment(paymentIntentId: paymentIntentId)
        Logger.info("Confirmando pago: \(paymentIntentId)")
        
        return networkDispatcher.dispatch(ApiResponse<PaymentConfirmationResponse>.self, endpoint)
            .map { response -> PaymentConfirmationResponse in
                Logger.info("Pago confirmado: \(response.data.success)")
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError> {
        let endpoint = PaymentEndpoints.cancelPayment(paymentIntentId: paymentIntentId)
        Logger.info("Cancelando pago: \(paymentIntentId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ in
                Logger.info("Pago cancelado exitosamente")
                return ()
            }
            .eraseToAnyPublisher()
    }
} 