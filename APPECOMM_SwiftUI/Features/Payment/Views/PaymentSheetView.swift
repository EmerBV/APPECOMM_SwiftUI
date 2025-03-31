//
//  PaymentSheetView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import SwiftUI
import Stripe
import StripePaymentSheet

struct PaymentSheetView: View {
    @StateObject var viewModel: PaymentSheetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isPaymentSheetPresented = false
    @State private var paymentError: PaymentError?
    
    var body: some View {
        VStack(spacing: 24) {
            headerSection
            
            if viewModel.isLoading {
                loadingView
            } else {
                switch viewModel.paymentStatus {
                case .idle, .loading, .ready:
                    paymentButton
                case .processing:
                    processingView
                case .completed:
                    successView
                case .failed(let message):
                    failureView(message: message)
                }
            }
        }
        .padding()
        .navigationTitle("Pago Seguro")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.preparePaymentSheet()
        }
        .alert(item: $paymentError) { error in
            Alert(
                title: Text("Error de Pago"),
                message: Text(error.message),
                dismissButton: .default(Text("Aceptar"))
            )
        }
        .onChange(of: viewModel.error) { errorMsg in
            if let errorMsg = errorMsg {
                paymentError = PaymentError.paymentFailed(errorMsg)
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Finalizar Compra")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Total a pagar: \(viewModel.amountFormatted)")
                .font(.headline)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Preparando información de pago...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var paymentButton: some View {
        VStack(spacing: 16) {
            Button {
                if viewModel.paymentSheet != nil {
                    isPaymentSheetPresented = true
                } else {
                    viewModel.preparePaymentSheet()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Pagar Ahora")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.paymentSheet == nil)
            .modifier(PaymentSheetViewModifier(
                isPresented: $isPaymentSheetPresented,
                paymentSheet: viewModel.paymentSheet,
                onCompletion: { result in
                    viewModel.handlePaymentResult(result)
                }
            ))
            
            Text("Pago seguro procesado por Stripe")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Procesando su pago...")
                .font(.headline)
            
            Text("Por favor espere mientras completamos la transacción")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.green)
                    .frame(width: 60, height: 60)
            }
            
            Text("¡Pago Completado!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Gracias por su compra. Hemos recibido su pago y estamos procesando su pedido.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private func failureView(message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.red)
                    .frame(width: 60, height: 60)
            }
            
            Text("Error en el Pago")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.reset()
                viewModel.preparePaymentSheet()
            } label: {
                Text("Intentar Nuevamente")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Cancelar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }
}
