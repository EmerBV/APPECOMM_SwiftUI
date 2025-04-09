//
//  OrderReviewView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct OrderReviewView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Order summary section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Order Summary")
                        .font(.headline)
                    
                    if let cart = viewModel.cart, !cart.items.isEmpty {
                        ForEach(cart.items) { item in
                            OrderReviewItemRow(item: item)
                        }
                    } else {
                        Text("No items in cart")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Shipping information section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shipping Information")
                        .font(.headline)
                    
                    if let selectedAddress = viewModel.selectedAddress {
                        ShippingDetailsSection(details: selectedAddress)
                    } else if let selectedId = viewModel.selectedShippingAddressId,
                              let address = viewModel.shippingAddresses.first(where: { $0.id == selectedId }) {
                        ShippingDetailsSection(details: address)
                    } else if viewModel.hasExistingShippingDetails, let details = viewModel.existingShippingDetails {
                        ShippingDetailsSection(details: details)
                    } else {
                        ShippingFormSummary(form: viewModel.shippingDetailsForm)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Payment method section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: viewModel.selectedPaymentMethod.iconName)
                            .foregroundColor(.blue)
                        Text(viewModel.selectedPaymentMethod.displayName)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Total summary
                VStack(spacing: 16) {
                    HStack {
                        Text("Subtotal")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.subtotal.toCurrentLocalePrice)
                    }
                    
                    HStack {
                        Text("Tax")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.tax.toCurrentLocalePrice)
                    }
                    
                    HStack {
                        Text("Shipping")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.formattedShipping)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.orderSummary.total.toCurrentLocalePrice)
                            .font(.headline)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                PrimaryButton(
                    title: "Place Order",
                    isLoading: viewModel.isLoading,
                    isEnabled: true
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Review Order")
        .onAppear {
            // Asegurarse de que los detalles de envío estén cargados
            viewModel.loadExistingShippingDetails()
            viewModel.ensureShippingAddressSelected()
        }
    }
}
