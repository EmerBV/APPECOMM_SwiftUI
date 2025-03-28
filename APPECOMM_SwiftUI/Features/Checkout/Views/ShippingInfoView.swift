//
//  ShippingInfoView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

// MARK: - Shipping Info View
struct ShippingInfoView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Shipping Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Contenido: detalles existentes o formulario
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.hasExistingShippingDetails && !viewModel.isEditingShippingDetails {
                        // Mostrar detalles existentes
                        existingShippingDetailsView
                    } else {
                        // Mostrar formulario
                        AddressFormFields(viewModel: viewModel)
                    }
                    
                    // Order summary
                    OrderSummaryCard(viewModel: viewModel)
                    
                    // Continue button
                    PrimaryButton(
                        title: "Continue to Payment",
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.hasExistingShippingDetails || viewModel.shippingDetailsForm.isValid
                    ) {
                        viewModel.proceedToNextStep()
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
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
    
    // Vista para mostrar detalles de envío existentes
    private var existingShippingDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Encabezado con botón de editar
            HStack {
                Text("Your Shipping Address")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.isEditingShippingDetails = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Detalles de la dirección
            if let details = viewModel.existingShippingDetails {
                VStack(alignment: .leading, spacing: 6) {
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
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
}
