import Foundation
import Combine
import Stripe

protocol PaymentServiceProtocol {
    /// Obtiene la configuración de Stripe desde el servidor
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError>
    
    /// Crea un intent de pago para una orden
    /// - Parameters:
    ///   - orderId: El ID de la orden
    ///   - request: Los datos de la solicitud de pago
    /// - Returns: Un publisher con la respuesta del intent de pago
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError>
    
    /// Confirma un pago
    /// - Parameters:
    ///   - paymentIntentId: El ID del intent de pago
    ///   - paymentMethodId: El ID del método de pago
    /// - Returns: Un publisher con la respuesta de confirmación
    func confirmPayment(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError>
    
    /// Cancela un pago
    /// - Parameter paymentIntentId: El ID del intent de pago
    /// - Returns: Un publisher con void en caso de éxito
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError>
    
    /// Crea un método de pago con los detalles de una tarjeta
    /// - Parameter cardDetails: Los detalles de la tarjeta
    /// - Returns: Un publisher con el ID del método de pago creado
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, Error>
    
    /// Crea un cliente en Stripe
    /// - Parameters:
    ///   - userId: El ID del usuario
    ///   - email: El email del usuario
    /// - Returns: Un publisher con el cliente creado
    func createCustomer(userId: Int, email: String) -> AnyPublisher<StripeCustomer, Error>
    
    /// Prepara un checkout completo
    /// - Parameters:
    ///   - orderId: El ID de la orden
    ///   - amount: El monto a pagar
    ///   - email: El email del cliente (opcional)
    /// - Returns: Un publisher con la información de checkout
    func prepareCheckout(orderId: Int, amount: Decimal, email: String?) -> AnyPublisher<PaymentCheckout, Error>
    
    /// Maneja el resultado de un pago
    /// - Parameters:
    ///   - result: El resultado de la acción del manejador de pagos
    ///   - error: El error, si existe
    /// - Returns: Un publisher con un booleano indicando el éxito
    func handlePaymentResult(_ result: STPPaymentHandlerActionStatus, error: Error?) -> AnyPublisher<Bool, Error>
}

struct PaymentCheckout {
    let clientSecret: String
    let ephemeralKey: String?
    let customerId: String?
    let paymentIntentId: String
}

final class PaymentService: PaymentServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    private let stripeService: StripeServiceProtocol
    private let stripeAPIClient: StripeAPIClientProtocol
    
    /// Inicializa el servicio de pagos con sus dependencias
    /// - Parameters:
    ///   - networkDispatcher: El dispatcher de red para comunicación con la API
    ///   - stripeService: El servicio local de Stripe
    ///   - stripeAPIClient: El cliente API de Stripe
    init(
        networkDispatcher: NetworkDispatcherProtocol,
        stripeService: StripeServiceProtocol,
        stripeAPIClient: StripeAPIClientProtocol
    ) {
        self.networkDispatcher = networkDispatcher
        self.stripeService = stripeService
        self.stripeAPIClient = stripeAPIClient
    }
    
    // MARK: - Stripe Configuration
    
    func getStripeConfig() -> AnyPublisher<StripeConfig, NetworkError> {
        return stripeAPIClient.getStripeConfig()
            .handleEvents(receiveOutput: { [weak self] config in
                // También inicializar el servicio de Stripe
                self?.stripeService.initialize(with: config)
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Payment Intent Management
    
    func createPaymentIntent(orderId: Int, request: PaymentRequest) -> AnyPublisher<PaymentIntentResponse, NetworkError> {
        return stripeAPIClient.createPaymentIntent(orderId: orderId, paymentRequest: request)
    }
    
    func confirmPayment(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<PaymentConfirmationResponse, NetworkError> {
        return stripeAPIClient.confirmPaymentIntent(paymentIntentId: paymentIntentId, paymentMethodId: paymentMethodId)
    }
    
    func cancelPayment(paymentIntentId: String) -> AnyPublisher<Void, NetworkError> {
        return stripeAPIClient.cancelPaymentIntent(paymentIntentId: paymentIntentId)
    }
    
    // MARK: - Payment Method Creation
    
    func createPaymentMethod(cardDetails: CreditCardDetails) -> AnyPublisher<String, Error> {
        // Primero intentamos con el servicio local de Stripe
        return stripeService.createPaymentMethod(cardDetails: cardDetails)
            .map { $0 as String }
            .mapError { $0 as Error }
            .catch { error -> AnyPublisher<String, Error> in
                // Si falla, intentamos con la API de Stripe
                Logger.payment("Local Stripe service failed, trying API client: \(error)", level: .warning)
                return self.stripeAPIClient.createPaymentMethod(withCard: cardDetails)
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Customer Management
    
    func createCustomer(userId: Int, email: String) -> AnyPublisher<StripeCustomer, Error> {
        return stripeAPIClient.createCustomer(userId: userId, email: email)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Complete Checkout Flow
    
    func prepareCheckout(orderId: Int, amount: Decimal, email: String?) -> AnyPublisher<PaymentCheckout, Error> {
        // Verificar que el orderId sea válido
        guard orderId > 0 else {
            return Fail(error: NetworkError.badRequest(APIError(
                message: "Invalid order ID",
                code: "INVALID_ORDER_ID",
                details: nil
            )))
            .eraseToAnyPublisher()
        }
        
        // 1. Crear PaymentIntent sin paymentMethodId
        let paymentRequest = PaymentRequest(paymentMethodId: nil)
        
        return createPaymentIntent(orderId: orderId, request: paymentRequest)
            .mapError { $0 as Error }
            .map { response -> PaymentCheckout in
                return PaymentCheckout(
                    clientSecret: response.clientSecret,
                    ephemeralKey: nil,
                    customerId: nil,
                    paymentIntentId: response.paymentIntentId
                )
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Payment Result Handling
    
    func handlePaymentResult(_ result: STPPaymentHandlerActionStatus, error: Error?) -> AnyPublisher<Bool, Error> {
        return stripeService.handlePaymentResult(result, error: error)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
