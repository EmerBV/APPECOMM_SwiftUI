//
//  StripePaymentConfirmationView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI
import Stripe
import StripePaymentSheet

struct StripePaymentConfirmationView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @State private var paymentSheet: PaymentSheet?
    @State private var isPaymentSheetPresented = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Preparing payment...")
            } else if let paymentSheetVM = viewModel.paymentSheetViewModel {
                Button("Complete Payment") {
                    if paymentSheetVM.clientSecret != nil {
                        preparePaymentSheet()
                        isPaymentSheetPresented = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(paymentSheetVM.clientSecret == nil || paymentSheet == nil)
            } else {
                Text("Waiting for payment information...")
            }
        }
        .onAppear {
            preparePaymentSheet()
        }
        .modifier(PaymentSheetViewModifier(
            isPresented: $isPaymentSheetPresented,
            paymentSheet: paymentSheet,
            onCompletion: handlePaymentResult
        ))
    }
    
    private func preparePaymentSheet() {
        guard let paymentSheetVM = viewModel.paymentSheetViewModel,
              let clientSecret = paymentSheetVM.clientSecret else {
            return
        }
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "APPECOMM"
        if !viewModel.creditCardDetails.cardholderName.isEmpty {
            configuration.defaultBillingDetails.name = viewModel.creditCardDetails.cardholderName
        }
        
        self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
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
