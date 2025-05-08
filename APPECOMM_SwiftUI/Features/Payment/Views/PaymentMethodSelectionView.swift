//
//  PaymentMethodSelectionView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct PaymentMethodSelectionView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("select_payment_method".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Payment method options
                    VStack(spacing: 16) {
                        ForEach(PaymentMethodOptions.allCases) { method in
                            PaymentMethodCard(
                                method: method,
                                isSelected: viewModel.selectedPaymentMethod == method,
                                action: { viewModel.selectedPaymentMethod = method }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                // Añadir padding inferior para evitar que el contenido quede detrás del botón
                .padding(.bottom, 80)
            }
            
            // Botón fijo en la parte inferior
            VStack {
                PrimaryButton(
                    title: "review_order".localized,
                    isLoading: false,
                    isEnabled: true
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethodOptions
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 40)
                
                Text(method.displayName)
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
