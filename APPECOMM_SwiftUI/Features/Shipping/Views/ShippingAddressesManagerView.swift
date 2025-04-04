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
    @State private var showingAddressForm = false
    @State private var editingAddress: ShippingDetails? = nil
    @State private var showingDeleteConfirmation = false
    @State private var addressToDelete: Int? = nil
    
    init(userId: Int) {
        self.userId = userId
        // Inicializamos el ViewModel usando el DependencyInjector existente
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
                
                // Error toast if needed
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .navigationTitle("Shipping Addresses")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingAddress = nil
                        showingAddressForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddressForm) {
                // Usar la vista de formulario existente
                ShippingAddressFormView(
                    userId: userId,
                    address: editingAddress,
                    onSave: { _ in
                        // Recargar la lista después de guardar
                        viewModel.loadAddresses(userId: userId)
                        showingAddressForm = false
                    }
                )
            }
            .refreshable {
                // Recargar direcciones de forma asíncrona
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
                editingAddress = nil
                showingAddressForm = true
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
                    isEditing: { editingAddress = address; showingAddressForm = true },
                    isDeleting: { addressToDelete = address.id; showingDeleteConfirmation = true },
                    isSettingDefault: { setDefaultAddress(addressId: address.id ?? 0) }
                )
                // Importante: Aquí no hay .onTapGesture que provoque cambios en el estado predeterminado
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // Métodos auxiliares para operaciones asincrónicas
    private func refreshAddresses() async {
        viewModel.loadAddresses(userId: userId)
        // Esperar brevemente para simular operación asíncrona
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func setDefaultAddress(addressId: Int) {
        viewModel.setDefaultAddress(userId: userId, addressId: addressId)
    }
    
    private func deleteAddress(addressId: Int) {
        viewModel.deleteAddress(userId: userId, addressId: addressId)
    }
}

// Actualización del componente de fila de dirección
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
                
                // Menú de opciones para acciones explícitas
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
            // Al tocar la celda simplemente se edita, no se establece como predeterminada
            isEditing()
        }
    }
}
