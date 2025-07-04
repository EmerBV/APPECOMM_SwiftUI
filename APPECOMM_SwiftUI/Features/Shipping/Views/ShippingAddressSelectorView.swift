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
            headerView
            addressesListView
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
        
        /*
        .overlay(
            viewModel.isLoading ? LoadingView() : nil
        )
         */
        
        .circularLoading(
            isLoading: viewModel.isLoading,
            message: "loading".localized,
            strokeColor: .blue,
            backgroundColor: .gray.opacity(0.1),
            showBackdrop: true,
            containerSize: 80,
            logoSize: 50
        )
    }
    
    private var headerView: some View {
        HStack {
            Text("select_shipping_address".localized)
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
    }
    
    private var addressesListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.shippingAddresses.compactMap { $0.id }, id: \.self) { addressId in
                    if let address = viewModel.shippingAddresses.first(where: { $0.id == addressId }) {
                        AddressCard(
                            address: address,
                            isSelected: viewModel.selectedShippingAddressId == addressId,
                            onSelect: {
                                viewModel.selectShippingAddress(id: addressId)
                            },
                            onSetDefault: {
                                viewModel.setAddressAsDefault(id: addressId)
                            },
                            onDelete: {
                                showingDeleteConfirmation = addressId
                            }
                        )
                    }
                }
                
                addNewAddressButton
            }
            .padding(.horizontal)
        }
    }
    
    private var addNewAddressButton: some View {
        Button(action: {
            viewModel.shippingDetailsForm = ShippingDetailsForm()
            viewModel.isAddingNewAddress = true
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("add_new_address".localized)
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
                            Text("default_label".localized)
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
                        Text("set_as_default".localized)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                }
                
                Button(action: onDelete) {
                    Text("delete_btn_address".localized)
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


