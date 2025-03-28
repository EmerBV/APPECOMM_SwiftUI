//
//  OrderReviewView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
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
                    
                    if viewModel.hasExistingShippingDetails, let details = viewModel.existingShippingDetails {
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
                    
                    if viewModel.selectedPaymentMethod == .creditCard {
                        CreditCardSummaryView(details: viewModel.creditCardDetails)
                    } else {
                        HStack {
                            Image(systemName: viewModel.selectedPaymentMethod.iconName)
                                .foregroundColor(.blue)
                            Text(viewModel.selectedPaymentMethod.displayName)
                                .fontWeight(.semibold)
                        }
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
                        Text(viewModel.orderSummary.formattedSubtotal)
                    }
                    
                    HStack {
                        Text("Tax")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.formattedTax)
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
                        Text(viewModel.orderSummary.formattedTotal)
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
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Helper views for review screen
struct OrderReviewItemRow: View {
    let item: CartItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text("\(item.quantity)×")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let variantName = item.variantName {
                    Text("Variant: \(variantName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(item.totalPrice.toCurrentLocalePrice)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

struct ShippingDetailsSection: View {
    let details: ShippingDetailsResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let fullName = details.fullName {
                Text(fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(details.address)
                .font(.subheadline)
            
            Text("\(details.city), \(details.state ?? "") \(details.postalCode)")
                .font(.subheadline)
            
            Text(details.country)
                .font(.subheadline)
            
            if let phoneNumber = details.phoneNumber {
                Text(phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ShippingFormSummary: View {
    let form: ShippingDetailsForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(form.fullName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(form.address)
                .font(.subheadline)
            
            Text("\(form.city), \(form.state) \(form.postalCode)")
                .font(.subheadline)
            
            Text(form.country)
                .font(.subheadline)
            
            Text(form.phoneNumber)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct CreditCardSummaryView: View {
    let details: CreditCardDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
                
                Text("•••• \(details.cardNumber.suffix(4))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(details.cardholderName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Expires: \(details.expiryDate)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
