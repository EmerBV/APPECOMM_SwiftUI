//
//  ShippingAddressSelectorView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct ShippingAddressSelectorView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @State private var showingDeleteConfirmation: Int? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Título y botón de cierre
            HStack {
                Text("Select Shipping Address")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            // Lista de direcciones
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.shippingAddresses, id: \.id) { address in
                        AddressCard(
                            address: address,
                            isSelected: viewModel.selectedShippingAddressId == address.id,
                            onSelect: {
                                viewModel.selectShippingAddress(id: address.id)
                            },
                            onSetDefault: {
                                viewModel.setAddressAsDefault(id: address.id)
                            },
                            onDelete: {
                                showingDeleteConfirmation = address.id
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Botón para agregar nueva dirección
                Button(action: {
                    // Resetear formulario y mostrar vista de agregar dirección
                    viewModel.shippingDetailsForm = ShippingDetailsForm()
                    viewModel.isAddingNewAddress = true
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Address")
                    }
                    .padding()
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .padding()
            }
        }
        .alert(item: $showingDeleteConfirmation) { addressId in
            Alert(
                title: Text("Delete Address"),
                message: Text("Are you sure you want to delete this address?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteShippingAddress(id: addressId)
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            viewModel.isLoading ? LoadingView() : nil
        )
    }
}

// Tarjeta para una dirección individual
struct AddressCard: View {
    let address: ShippingDetails
    let isSelected: Bool
    let onSelect: () -> Void
    let onSetDefault: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Radio button
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Nombre y badge de predeterminado
                    HStack {
                        Text(address.fullName ?? "")
                            .font(.headline)
                        
                        if address.isDefault ?? false {
                            Text("Default")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    // Dirección
                    Text(address.address ?? "")
                        .font(.subheadline)
                    
                    Text("\(address.city ?? ""), \(address.state ?? "") \(address.postalCode ?? "")")
                        .font(.subheadline)
                    
                    Text(address.country ?? "")
                        .font(.subheadline)
                    
                    if let phone = address.phoneNumber, !phone.isEmpty {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
                
                Spacer()
            }
            
            // Botones de acción
            HStack {
                Spacer()
                
                if !(address.isDefault ?? false) {
                    Button(action: onSetDefault) {
                        Text("Set as Default")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                }
                
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                .background(Color.white)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

// Helper para representar el ID como Identifiable para alertas
extension Int: Identifiable {
    public var id: Int {
        return self
    }
}
