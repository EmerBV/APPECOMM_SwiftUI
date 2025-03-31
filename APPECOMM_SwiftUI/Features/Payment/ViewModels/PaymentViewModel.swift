import Foundation
import Combine
import SwiftUI
import Stripe
import StripePaymentSheet

class PaymentViewModel: ObservableObject {
    private let paymentService: PaymentServiceProtocol
    private let stripeService: StripeServiceProtocol
    private let networkDispatcher: NetworkDispatcher
    private let stripeAPIClient: STPAPIClient
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
    
    init(networkDispatcher: NetworkDispatcher = NetworkDispatcher(),
         stripeService: StripeServiceProtocol = StripeService(),
         stripeAPIClient: STPAPIClient = STPAPIClient(publishableKey: "")) {
        self.networkDispatcher = networkDispatcher
        self.stripeService = stripeService
        self.stripeAPIClient = stripeAPIClient
        self.paymentService = PaymentService(networkDispatcher: networkDispatcher,
                                             stripeService: stripeService,
                                             stripeAPIClient: stripeAPIClient)
        loadStripeConfig()
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
    
    func processPayment(orderId: Int, card: STPPaymentMethodCardParams) {
        isLoading = true
        currentStep = .processing
        paymentStatus = .processing
        
        stripeService.createPaymentMethod(card: card)
            .flatMap { [weak self] paymentMethodId -> AnyPublisher<PaymentIntentResponse, PaymentError> in
                guard let self = self else {
                    return Fail(error: .paymentFailed("Error de referencia")).eraseToAnyPublisher()
                }
                
                let request = PaymentRequest(paymentMethodId: paymentMethodId)
                return self.paymentService.createPaymentIntent(orderId: orderId, request: request)
                    .mapError { PaymentError.paymentFailed($0.localizedDescription) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                    self?.paymentStatus = .failed
                    self?.currentStep = .error
                }
            } receiveValue: { [weak self] response in
                self?.confirmPayment(paymentIntentId: response.paymentIntentId)
            }
            .store(in: &cancellables)
    }
    
    private func confirmPayment(paymentIntentId: String) {
        paymentService.confirmPayment(paymentIntentId: paymentIntentId)
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
} 
