//
//  PaymentConfirmationView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct PaymentConfirmationView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Binding var shouldDismiss: Bool
    @State private var navigateToOrderDetails = false
    
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
                            Text(APPFormatters.formattedDateString(from: order.orderDate))
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
                            Text(viewModel.orderSummary.total.toCurrentLocalePrice)
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
                    // Return to home screen
                    shouldDismiss = true
                    
                    // Post notification to navigate to home tab
                    NotificationCenter.default.post(
                        name: Notification.Name("NavigateToHomeTab"),
                        object: nil
                    )
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
                if let order = viewModel.order {
                    Button(action: {
                        navigateToOrderDetails = true
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
                    .background(
                        NavigationLink(
                            destination: OrderDetailView(orderId: order.id),
                            isActive: $navigateToOrderDetails,
                            label: { EmptyView() }
                        )
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Payment Confirmation")
        .navigationBarBackButtonHidden(true)
    }
    
}

