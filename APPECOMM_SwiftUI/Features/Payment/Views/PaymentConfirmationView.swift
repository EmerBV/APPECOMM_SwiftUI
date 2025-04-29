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
        ScrollView(showsIndicators: false) {
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
                
                Text("payment_successful".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("thank_you_for_your_order".localized)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let order = viewModel.order {
                    // Order details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("order_details".localized)
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("order_number".localized)
                            Spacer()
                            Text("#\(order.id)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("date_label".localized)
                            Spacer()
                            Text(APPFormatters.formattedDateString(from: order.orderDate))
                        }
                        
                        HStack {
                            Text("order_total".localized)
                            Spacer()
                            Text(order.totalAmount.toCurrentLocalePrice)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        Text("a_confirmation_email".localized)
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
                        Text("order_summary".localized)
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("order_total".localized)
                            Spacer()
                            Text(viewModel.orderSummary.total.toCurrentLocalePrice)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        Text("a_confirmation_email".localized)
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
                    Text("continue_shopping_btn".localized)
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
                        Text("view_order_btn".localized)
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
        .navigationTitle("checkout_payment_confirmation".localized)
        .navigationBarBackButtonHidden(true)
    }
    
}

