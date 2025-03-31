//
//  StripePaymentConfirmationView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI
import Stripe

struct StripePaymentConfirmationView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @State private var paymentSheet: PaymentSheet?
    @State private var isPaymentSheetPresented = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Preparing payment...")
            } else if let paymentSheetVM = viewModel.paymentSheetViewModel, let clientSecret = paymentSheetVM.clientSecret {
                Button("Complete Payment") {
                    preparePaymentSheet(clientSecret: clientSecret)
                    isPaymentSheetPresented = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(paymentSheet == nil)
            } else {
                Text("Waiting for payment information...")
            }
        }
        .onAppear {
            if let paymentSheetVM = viewModel.paymentSheetViewModel, let clientSecret = paymentSheetVM.clientSecret {
                preparePaymentSheet(clientSecret: clientSecret)
            }
        }
        // Aplicar el modificador solo si paymentSheet existe
        .modifier(PaymentSheetViewModifier(
            isPresented: $isPaymentSheetPresented,
            paymentSheet: paymentSheet,
            onCompletion: handlePaymentResult
        ))
    }
    
    private func preparePaymentSheet(clientSecret: String) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "APPECOMM"
        if let cardholderName = viewModel.creditCardDetails.cardholderName, !cardholderName.isEmpty {
            configuration.defaultBillingDetails.name = cardholderName
        }
        
        paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
    }
    
    private func handlePaymentResult(_ result: PaymentSheetResult) {
        if let paymentSheetVM = viewModel.paymentSheetViewModel {
            paymentSheetVM.handlePaymentResult(result)
        } else {
            switch result {
            case .completed:
                viewModel.successMessage = "Payment completed successfully"
                viewModel.currentStep = .confirmation
            case .canceled:
                viewModel.errorMessage = "Payment canceled"
            case .failed(let error):
                viewModel.errorMessage = "Payment failed: \(error.localizedDescription)"
                viewModel.currentStep = .error
            }
        }
    }
}

// Modificador personalizado para manejar el paymentSheet opcional
struct PaymentSheetViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    var paymentSheet: PaymentSheet?
    var onCompletion: (PaymentSheetResult) -> Void
    
    func body(content: Content) -> some View {
        if let sheet = paymentSheet {
            content
                .paymentSheet(isPresented: $isPresented, paymentSheet: sheet, onCompletion: onCompletion)
        } else {
            content
        }
    }
}
