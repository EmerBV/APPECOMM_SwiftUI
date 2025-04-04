//
//  ShippingAddressesManagerView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct ShippingAddressesManagerView: View {
    let userId: Int
    @StateObject private var viewModel = ShippingAddressesViewModel()
    @StateObject private var newAddressViewModel: ShippingAddressViewModel
    @StateObject private var editAddressViewModel: ShippingAddressViewModel
    @State private var isAddingNewAddress = false
    @State private var editingAddress: ShippingDetails? = nil
    @State private var showingDeleteConfirmation: Int? = nil
    @Environment(\.presentationMode) var presentationMode
    
    init(userId: Int) {
        self.userId = userId
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        _newAddressViewModel = StateObject(wrappedValue: ShippingAddressViewModel(shippingRepository: shippingRepository, userId: userId))
        _editAddressViewModel = StateObject(wrappedValue: ShippingAddressViewModel(shippingRepository: shippingRepository, userId: userId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                contentView
                
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationTitle("Shipping Addresses")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    isAddingNewAddress = true
                }
            )
            .sheet(isPresented: $isAddingNewAddress) {
                NavigationView {
                    ShippingAddressFormView(
                        viewModel: newAddressViewModel,
                        addressId: nil
                    )
                }
            }
            .sheet(item: $editingAddress) { address in
                NavigationView {
                    ShippingAddressFormView(
                        viewModel: editAddressViewModel,
                        addressId: address.id
                    )
                    .onAppear {
                        if let addressId = address.id {
                            editAddressViewModel.loadAddressDetails(addressId: addressId)
                        }
                    }
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
            .onAppear {
                viewModel.loadShippingAddresses(userId: userId)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.addresses.isEmpty {
            emptyAddressesView
        } else {
            addressListView
        }
    }
    
    private var emptyAddressesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.circle")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Shipping Addresses")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add your first shipping address to make checkout faster.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                isAddingNewAddress = true
            }) {
                Text("Add Address")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var addressListView: some View {
        List {
            ForEach(viewModel.addresses.compactMap { $0.id }, id: \.self) { addressId in
                if let address = viewModel.addresses.first(where: { $0.id == addressId }) {
                    AddressListItem(
                        address: address,
                        onSetDefault: {
                            viewModel.setDefaultShippingAddress(userId: userId, addressId: addressId)
                        },
                        onEdit: {
                            editingAddress = address
                        },
                        onDelete: {
                            showingDeleteConfirmation = addressId
                        }
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct AddressListItem: View {
    let address: ShippingDetails
    let onSetDefault: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cabecera con nombre y badge de predeterminado
            HStack {
                Text(address.fullName ?? "")
                    .font(.headline)
                
                Spacer()
                
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
            Group {
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
            
            // Botones de acción
            HStack(spacing: 20) {
                Spacer()
                
                // Botón de editar
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                
                // Botón de establecer como predeterminada
                if address.isDefault != true {
                    Button(action: onSetDefault) {
                        Text("Set as Default")
                            .font(.footnote)
                            .foregroundColor(.green)
                    }
                }
                
                // Botón de eliminar
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
