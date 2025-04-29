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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Order summary section
                VStack(alignment: .leading, spacing: 16) {
                    Text("order_summary".localized)
                        .font(.headline)
                    
                    if let cart = viewModel.cart, !cart.items.isEmpty {
                        ForEach(cart.items) { item in
                            OrderReviewItemRow(item: item)
                        }
                    } else {
                        Text("no_items_in_cart".localized)
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
                    Text("shipping_information".localized)
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
                    Text("order_payment_method".localized)
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
                        Text("subtotal".localized)
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.subtotal.toCurrentLocalePrice)
                    }
                    
                    HStack {
                        Text("tax_label".localized)
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.tax.toCurrentLocalePrice)
                    }
                    
                    HStack {
                        Text("shipping".localized)
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.formattedShipping)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("total".localized)
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
                    title: "place_order".localized,
                    isLoading: viewModel.isLoading,
                    isEnabled: true
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("review_order".localized)
        .onAppear {
            // Asegurarse de que los detalles de envío estén cargados
            viewModel.loadExistingShippingDetails()
            viewModel.ensureShippingAddressSelected()
        }
    }
}
