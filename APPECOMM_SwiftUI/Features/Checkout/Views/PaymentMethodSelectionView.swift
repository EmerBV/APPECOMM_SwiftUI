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
        ScrollView {
            VStack(spacing: 20) {
                Text("Select Payment Method")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Payment method options
                VStack(spacing: 16) {
                    ForEach(PaymentMethod.allCases) { method in
                        PaymentMethodCard(
                            method: method,
                            isSelected: viewModel.selectedPaymentMethod == method,
                            action: { viewModel.selectedPaymentMethod = method }
                        )
                    }
                }
                .padding(.horizontal)
                
                OrderSummaryCard(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Continue button
                PrimaryButton(
                    title: "Continue",
                    isLoading: false,
                    isEnabled: true
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding([.top, .horizontal])
            }
            .padding(.vertical)
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
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
