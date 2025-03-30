import Foundation
import Combine

protocol PaymentServiceProtocol {
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError>
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    func confirmPayment(paymentIntentId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError>
}

final class PaymentService: PaymentServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    private let stripeService: StripeServiceProtocol
    private let stripeAPIClient: StripeAPIClientProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol = DependencyInjector.shared.resolve(NetworkDispatcherProtocol.self),
         stripeService: StripeServiceProtocol = DependencyInjector.shared.resolve(StripeServiceProtocol.self),
         stripeAPIClient: StripeAPIClientProtocol = DependencyInjector.shared.resolve(StripeAPIClientProtocol.self)) {
        self.networkDispatcher = networkDispatcher
        self.stripeService = stripeService
        self.stripeAPIClient = stripeAPIClient
    }
    
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError> {
        let endpoint = PaymentEndpoints.getStripeConfig
        Logger.info("Obteniendo configuración de Stripe")
        
        return networkDispatcher.dispatch(ApiResponse<StripeConfig>.self, endpoint)
            .handleEvents(receiveOutput: { [weak self] response in
                // Configurar Stripe SDK con la clave publicable
                self?.stripeAPIClient.configure(with: response.data.publicKey)
            })
            .map { $0.data }
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
