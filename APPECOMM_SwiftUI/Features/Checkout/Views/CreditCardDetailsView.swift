//
//  CreditCardDetailsView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI
import Stripe

struct CreditCardDetailsView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvc = ""
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("Procesando pago...")
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Detalles de la tarjeta")
                        .font(.headline)
                    
                    TextField("Número de tarjeta", text: $cardNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: cardNumber) { newValue in
                            cardNumber = newValue.filter { $0.isNumber }
                        }
                    
                    HStack {
                        TextField("MM/AA", text: $expiryDate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: expiryDate) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 2 {
                                    let month = filtered.prefix(2)
                                    let year = filtered.dropFirst(2)
                                    expiryDate = "\(month)/\(year)"
                                } else {
                                    expiryDate = filtered
                                }
                            }
                        
                        TextField("CVC", text: $cvc)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: cvc) { newValue in
                                cvc = newValue.filter { $0.isNumber }
                            }
                    }
                    
                    TextField("Nombre en la tarjeta", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        // Actualizar los detalles de la tarjeta en el viewModel
                        viewModel.creditCardDetails = CreditCardDetails(
                            cardNumber: cardNumber,
                            expiryDate: expiryDate,
                            cvv: cvc,
                            cardholderName: name
                        )
                        viewModel.processPayment()
                    }) {
                        HStack {
                            Text("Proceder al pago")
                            Text(String(format: "%.2f €", viewModel.calculateTotalAmount()))
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
                .padding()
            }
        }
        .sheet(isPresented: .init(
            get: { viewModel.showPaymentSheet },
            set: { viewModel.showPaymentSheet = $0 }
        )) {
            if let order = viewModel.order {
                let paymentVM = viewModel.paymentViewModel
                PaymentFormView(
                    viewModel: paymentVM,
                    orderId: order.id,
                    amount: NSDecimalNumber(decimal: order.totalAmount).doubleValue
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty &&
        cardNumber.count >= 16 &&
        !expiryDate.isEmpty &&
        expiryDate.count >= 5 &&
        !cvc.isEmpty &&
        cvc.count >= 3 &&
        !name.isEmpty
    }
}
