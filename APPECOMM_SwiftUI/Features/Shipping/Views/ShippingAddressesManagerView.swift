//
//  ShippingAddressesManagerView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct ShippingAddressesManagerView: View {
    let userId: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ShippingAddressesViewModel
    @State private var sheetMode: SheetMode = .none
    @State private var showingDeleteConfirmation = false
    @State private var addressToDelete: Int? = nil
    @State private var isSheetPresented = false
    @State private var selectedAddress: ShippingDetails? = nil
    
    // Enumeración para controlar el modo de la hoja modal
    enum SheetMode: Identifiable {
        case none
        case add
        case edit(addressId: Int)
        
        var id: String {
            switch self {
            case .none:
                return "none"
            case .add:
                return "add"
            case .edit(let addressId):
                return "edit_\(addressId)"
            }
        }
    }
    
    init(userId: Int) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DependencyInjector.shared.resolve(ShippingAddressesViewModel.self))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.addresses.isEmpty {
                    emptyStateView
                } else {
                    addressesList
                }
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .navigationTitle("Shipping Addresses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Logger.debug("Add button tapped")
                        selectedAddress = nil
                        isSheetPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isSheetPresented, onDismiss: {
                // Recargar direcciones al cerrar el formulario
                viewModel.loadAddresses(userId: userId)
            }) {
                AddressFormSheet(userId: userId, address: selectedAddress)
            }
            .refreshable {
                await refreshAddresses()
            }
            .alert("Delete Address", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let addressId = addressToDelete {
                        deleteAddress(addressId: addressId)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this address?")
            }
            .onAppear {
                viewModel.loadAddresses(userId: userId)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Addresses Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first shipping address to make checkout faster.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                Logger.debug("Add new address from empty state")
                selectedAddress = nil
                isSheetPresented = true
            }) {
                Label("Add Address", systemImage: "plus")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private var addressesList: some View {
        List {
            ForEach(viewModel.addresses, id: \.id) { address in
                AddressListItem(
                    address: address,
                    isEditing: {
                        guard let addressId = address.id else { return }
                        Logger.debug("Edit address: \(addressId)")
                        selectedAddress = address
                        isSheetPresented = true
                    },
                    isDeleting: {
                        addressToDelete = address.id
                        showingDeleteConfirmation = true
                    },
                    isSettingDefault: {
                        setDefaultAddress(addressId: address.id ?? 0)
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func refreshAddresses() async {
        viewModel.loadAddresses(userId: userId)
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func setDefaultAddress(addressId: Int) {
        viewModel.setDefaultAddress(userId: userId, addressId: addressId)
    }
    
    private func deleteAddress(addressId: Int) {
        viewModel.deleteAddress(userId: userId, addressId: addressId)
    }
}

// Vista contenedor para el formulario que maneja la extracción de dirección
struct AddressFormSheet: View {
    let userId: Int
    let address: ShippingDetails?
    
    var body: some View {
        ShippingAddressFormView(
            userId: userId,
            address: address,
            onSave: { _ in }
        )
    }
}

struct AddressListItem: View {
    let address: ShippingDetails
    let isEditing: () -> Void
    let isDeleting: () -> Void
    let isSettingDefault: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(address.fullName ?? "")
                        .font(.headline)
                    
                    if let isDefault = address.isDefault, isDefault {
                        Text("Default Address")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: isEditing) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if !(address.isDefault ?? false) {
                        Button(action: isSettingDefault) {
                            Label("Set as Default", systemImage: "checkmark.circle")
                        }
                    }
                    
                    Button(role: .destructive, action: isDeleting) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            Group {
                Text(address.address ?? "")
                Text("\(address.city ?? ""), \(address.state ?? "") \(address.postalCode ?? "")")
                Text(address.country ?? "")
                
                if let phone = address.phoneNumber {
                    Text(phone)
                        .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            isEditing()
        }
    }
}
