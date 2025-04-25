//
//  CheckoutView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI
import Stripe

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CheckoutViewModel
    @State private var showingPaymentForm = false
    @State private var selectedOrder: Order?
    @State private var shouldDismiss = false
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    
    // MARK: - Initialization
    
    init(cart: Cart?) {
        // Inject dependencies properly using DependencyInjector
        let dependencyInjector = DependencyInjector.shared
        _viewModel = StateObject(wrappedValue: dependencyInjector.resolve(CheckoutViewModel.self, arguments: cart))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            CheckoutContentView(
                viewModel: viewModel,
                showingPaymentForm: $showingPaymentForm,
                selectedOrder: $selectedOrder,
                shouldDismiss: $shouldDismiss
            )
            .fullScreenCover(isPresented: $viewModel.showPaymentSheet) {
                if let paymentSheetViewModel = viewModel.paymentSheetViewModel {
                    PaymentSheetView(viewModel: paymentSheetViewModel)
                }
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: shouldDismiss) { newValue in
            if newValue {
                // Primero publicamos la notificación para navegar al home tab
                NotificationCenter.default.post(name: Notification.Name("NavigateToHomeTab"), object: nil)
                // Luego cerramos la vista actual
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()
                }
            }
        }
        .onAppear {
            setupNotificationObservers()
        }
        // Observar cuando NavigationCoordinator indica que hay que cerrar esta vista
        .onChange(of: navigationCoordinator.shouldDismissCurrent) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("PaymentCancelled"),
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            viewModel?.currentStep = .review
        }
    }
}

// MARK: - CheckoutContentView

struct CheckoutContentView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Binding var showingPaymentForm: Bool
    @Binding var selectedOrder: Order?
    @Binding var shouldDismiss: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        contentView
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if canGoBack {
                        Button(action: viewModel.goBack) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                    } else if viewModel.currentStep == .shippingInfo {
                        // Solo mostramos el botón cancelar en la vista de envío
                        Button("cancel".localized) {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .confirmation {
                        Button("done".localized) {
                            shouldDismiss = true
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .alert("error".localized, isPresented: $viewModel.showError) {
                Button("ok".localized, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "an_error_occurred".localized)
            }
    }
    
    // MARK: - Content Views
    
    /// The main content view based on the current checkout step
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.currentStep {
        case .shippingInfo:
            ShippingInfoView(viewModel: viewModel)
        case .paymentMethod:
            PaymentMethodSelectionView(viewModel: viewModel)
        case .review:
            OrderReviewView(viewModel: viewModel)
        case .processing:
            PaymentProcessingView()
        case .confirmation:
            PaymentConfirmationView(viewModel: viewModel, shouldDismiss: $shouldDismiss)
        case .error:
            PaymentErrorView(viewModel: viewModel)
        }
    }
    
    /// Dynamic navigation title based on the current step
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .shippingInfo:
            return "shipping".localized
        case .paymentMethod:
            return "payment_method".localized
        case .review:
            return "order_review".localized
        case .processing:
            return "processing".localized
        case .confirmation:
            return "payment_confirmation".localized
        case .error:
            return "error".localized
        }
    }
    
    /// Determines if the back button should be shown
    private var canGoBack: Bool {
        switch viewModel.currentStep {
        case .shippingInfo, .processing, .confirmation, .error:
            return false
        default:
            return true
        }
    }
}

