//
//  PaymentSheetViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import Combine
import SwiftUI
import Stripe
import StripePaymentSheet

/// ViewModel específico para manejar el flujo de pago con PaymentSheet de Stripe
class PaymentSheetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: String?
    @Published var paymentStatus: PaymentStatus = .idle
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var clientSecret: String?
    @Published var shouldPresentPaymentSheet = false
    @Published var order: Order?
    
    // MARK: - Private Properties
    private let paymentService: PaymentServiceProtocol
    private let navigationCoordinator: NavigationCoordinatorProtocol
    private let orderId: Int
    private let amount: Decimal
    private let email: String?
    private var paymentIntentId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
    
    // MARK: - Initialization
    init(
        paymentService: PaymentServiceProtocol,
        orderId: Int,
        amount: Decimal,
        email: String? = nil,
        navigationCoordinator: NavigationCoordinatorProtocol = NavigationCoordinator.shared
    ) {
        self.paymentService = paymentService
        self.orderId = orderId
        self.amount = amount
        self.email = email
        self.navigationCoordinator = navigationCoordinator
    }
    
    // MARK: - Public Methods
    func preparePaymentSheet() {
        guard paymentSheet == nil else { return }
        
        isLoading = true
        paymentStatus = .loading
        
        paymentService.getStripeConfig()
            .mapError { $0 as Error }
            .flatMap { [weak self] config -> AnyPublisher<PaymentCheckout, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "PaymentSheetViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                        .eraseToAnyPublisher()
                }
                
                return self.paymentService.prepareCheckout(
                    orderId: self.orderId,
                    amount: self.amount,
                    email: self.email
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.error = error.localizedDescription
                    self.paymentStatus = .failed(error.localizedDescription)
                    Logger.payment("Failed to prepare payment: \(error)", level: .error)
                }
            } receiveValue: { [weak self] checkout in
                guard let self = self else { return }
                
                self.clientSecret = checkout.clientSecret
                self.paymentIntentId = checkout.paymentIntentId
                
                let paymentSheet = self.createPaymentSheet(
                    clientSecret: checkout.clientSecret,
                    customerId: checkout.customerId,
                    ephemeralKey: checkout.ephemeralKey
                )
                
                self.paymentSheet = paymentSheet
                self.isLoading = false
                self.paymentStatus = .ready
                Logger.payment("Payment sheet ready with client secret", level: .info)
            }
            .store(in: &cancellables)
    }
    
    private func createPaymentSheet(
        clientSecret: String,
        customerId: String?,
        ephemeralKey: String?
    ) -> PaymentSheet {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "APPECOMM"
        if let email = self.email {
            configuration.defaultBillingDetails.email = email
        }
        
        if let customerId = customerId,
           let ephemeralKey = ephemeralKey {
            configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
        }
        
        // Configurar la apariencia del PaymentSheet
        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = .systemBlue
        appearance.colors.background = .systemBackground
        appearance.colors.componentBackground = .secondarySystemBackground
        appearance.colors.componentBorder = .separator
        appearance.primaryButton.backgroundColor = .systemBlue
        appearance.primaryButton.textColor = .white
        appearance.primaryButton.cornerRadius = 10
        
        // Aplicar la configuración de apariencia
        configuration.appearance = appearance
        configuration.defaultBillingDetails.address.country = "ES"
        
        return PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
    }
    
    func presentPaymentSheetIfReady() {
        guard let paymentSheet = paymentSheet else {
            Logger.payment("PaymentSheet is nil", level: .error)
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            Logger.payment("Failed to get root view controller", level: .error)
            return
        }
        
        let presentingViewController = rootViewController.topMostViewController
        
        Logger.payment("Presenting PaymentSheet from topMostViewController", level: .info)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if presentingViewController.presentedViewController != nil {
                presentingViewController.dismiss(animated: true) {
                    paymentSheet.present(from: presentingViewController) { result in
                        self.shouldPresentPaymentSheet = false
                        self.handlePaymentResult(result)
                        Logger.payment("PaymentSheet presentation completed with result: \(result)", level: .info)
                    }
                }
            } else {
                paymentSheet.present(from: presentingViewController) { result in
                    self.shouldPresentPaymentSheet = false
                    self.handlePaymentResult(result)
                    Logger.payment("PaymentSheet presentation completed with result: \(result)", level: .info)
                }
            }
        }
    }
    
    public func handlePaymentResult(_ result: PaymentSheetResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Asegurarse de que el PaymentSheet se cierre
            self.shouldPresentPaymentSheet = false
            self.paymentSheet = nil
            
            switch result {
            case .completed:
                self.paymentStatus = .completed
                self.paymentResult = result
                // Solo notificar el éxito, no mostrar pantalla de confirmación
                NotificationCenter.default.post(
                    name: Notification.Name("PaymentCompleted"),
                    object: nil,
                    userInfo: ["orderId": self.orderId]
                )
                Logger.payment("Payment completed successfully", level: .info)
                
            case .canceled:
                self.paymentStatus = .failed("payment_cancelled".localized)
                
                // Notificar cancelación de pago
                NotificationCenter.default.post(
                    name: Notification.Name("PaymentCancelled"),
                    object: nil
                )
                Logger.payment("Payment was canceled", level: .info)
                
            case .failed(let error):
                self.paymentStatus = .failed(error.localizedDescription)
                self.error = error.localizedDescription
                Logger.payment("Payment failed: \(error.localizedDescription)", level: .error)
                
                // Notificar fallo de pago
                NotificationCenter.default.post(
                    name: Notification.Name("PaymentFailed"),
                    object: nil,
                    userInfo: ["error": error.localizedDescription]
                )
            }
        }
    }
}
