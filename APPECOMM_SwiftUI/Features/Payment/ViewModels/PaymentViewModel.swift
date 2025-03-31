import Foundation
import Combine
import SwiftUI
import Stripe
import StripePaymentSheet

class PaymentViewModel: ObservableObject {
    private let paymentService: PaymentServiceProtocol
    private let stripeService: StripeServiceProtocol
    private let stripeAPIClient: StripeAPIClientProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var paymentStatus: PaymentStatus = .idle
    @Published var stripeConfig: StripeConfig?
    @Published var currentStep: PaymentStep = .cardDetails
    
    enum PaymentStatus {
        case idle
        case processing
        case success
        case failed
        case cancelled
    }
    
    enum PaymentStep {
        case cardDetails
        case processing
        case confirmation
        case error
    }
    
    init(paymentService: PaymentServiceProtocol,
         stripeService: StripeServiceProtocol,
         stripeAPIClient: StripeAPIClientProtocol) {
        self.paymentService = paymentService
        self.stripeService = stripeService
        self.stripeAPIClient = stripeAPIClient
        loadStripeConfig()
    }
    
    // Constructor conveniente que usa inyección de dependencias
    convenience init() {
        let dependencies = DependencyInjector.shared
        let stripeService = dependencies.resolve(StripeServiceProtocol.self)
        let stripeAPIClient = dependencies.resolve(StripeAPIClientProtocol.self)
        let paymentService = dependencies.resolve(PaymentServiceProtocol.self)
        self.init(paymentService: paymentService, stripeService: stripeService, stripeAPIClient: stripeAPIClient)
    }
    
    private func loadStripeConfig() {
        isLoading = true
        paymentService.getStripeConfig()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                    self?.currentStep = .error
                }
            } receiveValue: { [weak self] config in
                self?.stripeConfig = config
                self?.stripeService.initialize(with: config)
            }
            .store(in: &cancellables)
    }
    
    private func processPayment(orderId: Int, cardDetails: CreditCardDetails) {
        isLoading = true
        error = nil
        paymentStatus = .processing
        
        stripeService.createPaymentMethod(cardDetails: cardDetails)
            .flatMap { [weak self] paymentMethodId -> AnyPublisher<PaymentIntentResponse, PaymentError> in
                guard let self = self else {
                    return Fail(error: .paymentFailed).eraseToAnyPublisher()
                }
                
                let request = PaymentRequest(paymentMethodId: paymentMethodId)
                return self.paymentService.createPaymentIntent(orderId: orderId, request: request)
                    .mapError { _ in PaymentError.paymentFailed }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.message
                    self?.paymentStatus = .failed
                    self?.currentStep = .error
                }
            } receiveValue: { [weak self] response in
                self?.confirmPayment(paymentIntentId: response.paymentIntentId, paymentMethodId: response.paymentIntentId)
            }
            .store(in: &cancellables)
    }
    
    // Método auxiliar para convertir STPPaymentMethodCardParams a CreditCardDetails
    private func convertToCardDetails(from cardParams: STPPaymentMethodCardParams) -> CreditCardDetails {
        var details = CreditCardDetails()
        details.cardNumber = cardParams.number ?? ""
        
        if let month = cardParams.expMonth?.intValue, let year = cardParams.expYear?.intValue {
            let lastTwoDigitsOfYear = year % 100
            details.expiryDate = "\(String(format: "%02d", month))/\(String(format: "%02d", lastTwoDigitsOfYear))"
        }
        
        details.cvv = cardParams.cvc ?? ""
        
        // Los datos del titular de la tarjeta no están disponibles en cardParams,
        // deberían provenir de STPPaymentMethodBillingDetails
        details.cardholderName = ""
        
        // Establecer todos los campos como válidos para evitar problemas de validación
        details.isCardNumberValid = true
        details.isExpiryDateValid = true
        details.isCvvValid = true
        details.isCardholderNameValid = true
        
        return details
    }
    
    private func confirmPayment(paymentIntentId: String, paymentMethodId: String) {
        paymentService.confirmPayment(paymentIntentId: paymentIntentId, paymentMethodId: paymentMethodId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                    self?.paymentStatus = .failed
                    self?.currentStep = .error
                }
            } receiveValue: { [weak self] response in
                self?.paymentStatus = response.success ? .success : .failed
                self?.currentStep = response.success ? .confirmation : .error
                if !response.success {
                    self?.error = response.message
                }
            }
            .store(in: &cancellables)
    }
    
    func cancelPayment(paymentIntentId: String) {
        isLoading = true
        paymentService.cancelPayment(paymentIntentId: paymentIntentId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.paymentStatus = .cancelled
                self?.currentStep = .cardDetails
            }
            .store(in: &cancellables)
    }
    
    func reset() {
        error = nil
        paymentStatus = .idle
        currentStep = .cardDetails
    }
    
    // MARK: - Public Methods
    
    func processPayment(orderId: Int, card: STPPaymentMethodCardParams) {
        isLoading = true
        currentStep = .processing
        paymentStatus = .processing
        
        // Convertir STPPaymentMethodCardParams a CreditCardDetails
        let cardDetails = convertToCardDetails(from: card)
        processPaymentWithDetails(orderId: orderId, cardDetails: cardDetails)
    }
    
    private func processPaymentWithDetails(orderId: Int, cardDetails: CreditCardDetails) {
        isLoading = true
        error = nil
        paymentStatus = .processing
        
        stripeService.createPaymentMethod(cardDetails: cardDetails)
            .flatMap { [weak self] paymentMethodId -> AnyPublisher<PaymentIntentResponse, PaymentError> in
                guard let self = self else {
                    return Fail(error: .paymentFailed).eraseToAnyPublisher()
                }
                
                let request = PaymentRequest(paymentMethodId: paymentMethodId)
                return self.paymentService.createPaymentIntent(orderId: orderId, request: request)
                    .mapError { _ in PaymentError.paymentFailed }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.message
                    self?.paymentStatus = .failed
                    self?.currentStep = .error
                }
            } receiveValue: { [weak self] response in
                self?.confirmPayment(paymentIntentId: response.paymentIntentId, paymentMethodId: response.paymentIntentId)
            }
            .store(in: &cancellables)
    }
    
    private func processPaymentWithCard(orderId: Int, card: STPPaymentMethodCardParams) {
        isLoading = true
        error = nil
        paymentStatus = .processing
        
        stripeService.createPaymentMethod(cardDetails: CreditCardDetails(
            cardNumber: card.number ?? "",
            expiryDate: "\(card.expMonth ?? 0)/\(card.expYear ?? 0)",
            cvv: card.cvc ?? "",
            cardholderName: ""
        ))
        .flatMap { [weak self] paymentMethodId -> AnyPublisher<PaymentIntentResponse, PaymentError> in
            guard let self = self else {
                return Fail(error: .paymentFailed).eraseToAnyPublisher()
            }
            
            let request = PaymentRequest(paymentMethodId: paymentMethodId)
            return self.paymentService.createPaymentIntent(orderId: orderId, request: request)
                .mapError { _ in PaymentError.paymentFailed }
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.error = error.message
                self?.paymentStatus = .failed
                self?.currentStep = .error
            }
        } receiveValue: { [weak self] response in
            self?.confirmPayment(paymentIntentId: response.paymentIntentId, paymentMethodId: response.paymentIntentId)
        }
        .store(in: &cancellables)
    }
}
