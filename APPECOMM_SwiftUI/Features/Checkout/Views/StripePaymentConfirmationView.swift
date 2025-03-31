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
                if let clientSecret = paymentSheetVM.clientSecret {
                    Button("Complete Payment") {
                        preparePaymentSheet(clientSecret: clientSecret)
                        isPaymentSheetPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(paymentSheet == nil)
                } else {
                    Text("Waiting for payment information...")
                }
            } else {
                Text("Waiting for payment information...")
            }
        }
        .onAppear {
            if let paymentSheetVM = viewModel.paymentSheetViewModel,
               let clientSecret = paymentSheetVM.clientSecret {
                preparePaymentSheet(clientSecret: clientSecret)
            }
        }
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
