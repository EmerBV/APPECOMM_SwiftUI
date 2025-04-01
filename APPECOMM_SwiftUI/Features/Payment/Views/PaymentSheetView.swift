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
    @State private var showingCancelConfirmation = false
    
    var body: some View {
        NavigationView {
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
                        failureView(errorMessage: message)
                    }
                }
            }
            .padding()
            .navigationTitle("Pago Seguro")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                showingCancelConfirmation = true
            })
            .alert("¿Cancelar el pago?", isPresented: $showingCancelConfirmation) {
                Button("No", role: .cancel) { }
                Button("Sí", role: .destructive) {
                    viewModel.cancelPayment()
                    NotificationCenter.default.post(name: Notification.Name("ReturnToCart"), object: nil)
                    dismiss()
                }
            } message: {
                Text("¿Estás seguro de que deseas cancelar el proceso de pago? Podrás volver a intentarlo más tarde desde tu carrito.")
            }
        }
        .onAppear {
            viewModel.preparePaymentSheet()
        }
        .onChange(of: viewModel.shouldPresentPaymentSheet) { shouldPresent in
            if shouldPresent {
                viewModel.presentPaymentSheetIfReady()
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
                Logger.payment("Payment button tapped", level: .info)
                viewModel.shouldPresentPaymentSheet = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Pagar Ahora")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.paymentSheet != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.paymentSheet == nil || viewModel.isLoading)
            
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
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("¡Pago Completado!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Gracias por su compra. Hemos recibido su pago y estamos procesando su pedido.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Button {
                    NotificationCenter.default.post(name: Notification.Name("ContinueShopping"), object: nil)
                    dismiss()
                } label: {
                    Text("Continuar Comprando")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button {
                    if let orderId = viewModel.order?.id {
                        NotificationCenter.default.post(
                            name: Notification.Name("ViewOrder"),
                            object: nil,
                            userInfo: ["orderId": orderId]
                        )
                    }
                    dismiss()
                } label: {
                    Text("Ver Pedido")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    private func failureView(errorMessage: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
            
            Text("Error en el Pago")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.preparePaymentSheet()
            } label: {
                Text("Intentar Nuevamente")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
