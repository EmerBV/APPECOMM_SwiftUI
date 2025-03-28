//
//  PaymentProcessingView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct PaymentProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProcessingAnimation()
                .frame(width: 200, height: 200)
            
            Text("Processing Your Payment")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please wait while we process your payment...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Processing Payment")
        .navigationBarBackButtonHidden(true)
    }
}

struct ProcessingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                .frame(width: 150, height: 150)
            
            // Animated arc
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            // Credit card icon
            Image(systemName: "creditcard.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Payment Confirmation View

struct PaymentConfirmationView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.green)
                        .frame(width: 80, height: 80)
                }
                .padding(.top, 30)
                
                Text("Payment Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Thank you for your order. Your payment has been processed successfully.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let order = viewModel.order {
                    // Order details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Details")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("Order Number")
                            Spacer()
                            Text("#\(order.id)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(formattedDate(from: order.orderDate))
                        }
                        
                        HStack {
                            Text("Order Total")
                            Spacer()
                            Text(order.totalAmount.toCurrentLocalePrice)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        Text("A confirmation email has been sent to your email address.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    // Order Summary if no order object is available
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Summary")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("Order Total")
                            Spacer()
                            Text(viewModel.orderSummary.formattedTotal)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        Text("A confirmation email has been sent to your email address.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Continue Shopping button
                Button(action: {
                    // Return to main screen
                    dismiss()
                }) {
                    Text("Continue Shopping")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                
                // View Order button
                if viewModel.order != nil {
                    Button(action: {
                        // Navigate to order details (would be implemented in a real app)
                    }) {
                        Text("View Order")
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
                }
            }
            .padding()
        }
        .navigationTitle("Payment Confirmation")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func formattedDate(from dateString: String) -> String {
        // Convert API date string to a formatted date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" // Adjust based on API date format
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return dateString // Return original if parsing fails
    }
}

// MARK: - Payment Error View

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
