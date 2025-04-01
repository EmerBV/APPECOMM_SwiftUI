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
    @Published var showingSavedOrderConfirmation = false
    
    private let navigationCoordinator: NavigationCoordinatorProtocol
    
    // MARK: - Private Properties
    private let paymentService: PaymentServiceProtocol
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
                
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "APPECOMM"
                if let email = self.email {
                    configuration.defaultBillingDetails.email = email
                }
                
                if let customerId = checkout.customerId,
                   let ephemeralKey = checkout.ephemeralKey {
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
                
                // Configurar el PaymentSheet
                configuration.appearance = appearance
                configuration.defaultBillingDetails.address.country = "ES"
                
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: checkout.clientSecret,
                    configuration: configuration
                )
                
                self.isLoading = false
                self.paymentStatus = .ready
                Logger.payment("Payment sheet ready with client secret", level: .info)
            }
            .store(in: &cancellables)
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
                self.paymentStatus = .failed("Pago cancelado")
                Logger.payment("Payment was canceled by user", level: .info)
                
            case .failed(let error):
                self.paymentStatus = .failed(error.localizedDescription)
                self.error = error.localizedDescription
                Logger.payment("Payment failed: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    func cancelPayment() {
        // Limpiar el estado del pago
        self.paymentSheet = nil
        self.shouldPresentPaymentSheet = false
        self.paymentStatus = .idle
        self.isLoading = false
        
        // Si hay un paymentIntentId activo, cancelarlo en el servidor
        if let paymentIntentId = self.paymentIntentId {
            paymentService.cancelPayment(paymentIntentId: paymentIntentId)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        Logger.payment("Error canceling payment: \(error)", level: .error)
                    }
                } receiveValue: { [weak self] _ in
                    Logger.payment("Payment cancelled successfully", level: .info)
                    // Notificar la cancelación del pago
                    NotificationCenter.default.post(
                        name: Notification.Name("PaymentCancelled"),
                        object: nil
                    )
                    // Asegurarse de que el estado se actualice
                    self?.paymentStatus = .failed("Pago cancelado por el usuario")
                }
                .store(in: &cancellables)
        } else {
            // Si no hay paymentIntentId, simplemente notificar la cancelación
            NotificationCenter.default.post(
                name: Notification.Name("PaymentCancelled"),
                object: nil
            )
            self.paymentStatus = .failed("Pago cancelado por el usuario")
        }
    }
    
    func saveOrderForLater() {
        // Limpiar el estado del pago sin cancelarlo en el servidor
        self.paymentSheet = nil
        self.shouldPresentPaymentSheet = false
        self.paymentStatus = .idle
        self.isLoading = false
        
        // Usar directamente orderId ya que no es opcional
        let dependencies = DependencyInjector.shared
        let checkoutService = dependencies.resolve(CheckoutServiceProtocol.self)
        
        checkoutService.updateOrderStatus(id: orderId, status: "pending")
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    Logger.payment("Error saving order for later: \(error)", level: .error)
                    
                    // A pesar del error, seguimos con el flujo para no bloquear al usuario
                    self.showingSavedOrderConfirmation = true
                }
            } receiveValue: { _ in
                Logger.payment("Order saved for later completion", level: .info)
                
                self.showingSavedOrderConfirmation = true
            }
            .store(in: &cancellables)
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController ?? self
        }
        return self
    }
}
