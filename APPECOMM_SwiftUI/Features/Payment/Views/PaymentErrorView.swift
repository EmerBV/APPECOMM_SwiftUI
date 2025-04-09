//
//  PaymentErrorView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct PaymentErrorView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.red)
                    .frame(width: 80, height: 80)
            }
            
            Text("Payment Failed")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.errorMessage ?? "There was a problem processing your payment. Please try again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Try Again button
            Button(action: {
                // Return to review screen to try again
                viewModel.currentStep = .review
                viewModel.errorMessage = nil
                //viewModel.preparePaymentSheet()
            }) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            // Go back to cart button
            Button(action: {
                // Return to cart screen
                dismiss()
            }) {
                Text("Return to Cart")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Payment Failed")
        .navigationBarBackButtonHidden(true)
    }
}
