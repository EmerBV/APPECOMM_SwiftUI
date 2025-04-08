//
//  ShippingAddressFormView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI
import Combine

struct ShippingAddressFormView: View {
    let userId: Int
    var address: ShippingDetails?
    let onSave: (ShippingDetails) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Creamos el viewModel directamente para cada instancia de la vista
    // en lugar de usar StateObject para evitar problemas de estado compartido
    @ObservedObject private var viewModel: ShippingAddressFormViewModel
    
    init(userId: Int, address: ShippingDetails? = nil, onSave: @escaping (ShippingDetails) -> Void) {
        self.userId = userId
        self.address = address
        self.onSave = onSave
        
        // Inicializar el ViewModel con dependencias
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        let validator = DependencyInjector.shared.resolve(InputValidatorProtocol.self)
        
        let formViewModel = ShippingAddressFormViewModel(
            shippingRepository: shippingRepository,
            validator: validator
        )
        
        // Si tenemos dirección, inicializamos el formulario de inmediato
        if let existingAddress = address {
            formViewModel.initializeForm(with: existingAddress)
        }
        
        self.viewModel = formViewModel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección de información de contacto
                Section(header: Text("Contact Information")) {
                    CustomTextField(
                        title: "Full Name",
                        placeholder: "John Doe",
                        type: .regular,
                        state: viewModel.form.isFullNameValid ? .valid : .normal,
                        text: $viewModel.form.fullName,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.fullName)
                            }
                        }
                    )
                    .keyboardType(.namePhonePad)
                    
                    CustomTextField(
                        title: "Phone Number",
                        placeholder: "+1 (555) 123-4567",
                        type: .regular,
                        state: viewModel.form.isPhoneNumberValid ? .valid : .normal,
                        text: $viewModel.form.phoneNumber,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.phoneNumber)
                            }
                        }
                    )
                    .keyboardType(.phonePad)
                }
                
                // Sección de dirección
                Section(header: Text("Address")) {
                    CustomTextField(
                        title: "Street Address",
                        placeholder: "123 Main St",
                        type: .regular,
                        state: viewModel.form.isAddressValid ? .valid : .normal,
                        text: $viewModel.form.address,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.address)
                            }
                        }
                    )
                    
                    CustomTextField(
                        title: "City",
                        placeholder: "New York",
                        type: .regular,
                        state: viewModel.form.isCityValid ? .valid : .normal,
                        text: $viewModel.form.city,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.city)
                            }
                        }
                    )
                    
                    CustomTextField(
                        title: "State/Province",
                        placeholder: "NY",
                        type: .regular,
                        state: viewModel.form.isStateValid ? .valid : .normal,
                        text: $viewModel.form.state,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.state)
                            }
                        }
                    )
                    
                    CustomTextField(
                        title: "Postal Code",
                        placeholder: "10001",
                        type: .regular,
                        state: viewModel.form.isPostalCodeValid ? .valid : .normal,
                        text: $viewModel.form.postalCode,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.postalCode)
                            }
                        }
                    )
                    .keyboardType(.numberPad)
                    
                    CustomTextField(
                        title: "Country",
                        placeholder: "United States",
                        type: .regular,
                        state: viewModel.form.isCountryValid ? .valid : .normal,
                        text: $viewModel.form.country,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.validateField(.country)
                            }
                        }
                    )
                }
                
                // Switch para establecer como dirección predeterminada
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.form.isDefaultAddress ?? false },
                        set: { viewModel.form.isDefaultAddress = $0 }
                    )) {
                        Text("Set as Default Address")
                    }
                    .accessibilityLabel("Set as Default Address")
                }
                
                // Botón de guardado
                Section {
                    Button(action: saveAddress) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Address")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .listRowInsets(EdgeInsets())
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isValid && !viewModel.isLoading ? Color.blue : Color.gray.opacity(0.5))
                    )
                }
            }
            .navigationTitle(address == nil ? "Add Address" : "Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            
            .overlay(alignment: .bottom) {
                if viewModel.showingSuccess {
                    SuccessToast(
                        message: viewModel.successMessage ?? "Address saved successfully!",
                        onDismiss: {
                            viewModel.showingSuccess = false
                        }
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.showingSuccess = false
                        }
                    }
                }
            }
        }
    }
    
    private func saveAddress() {
        Task {
            if await viewModel.saveAddress(userId: userId, existingAddressId: address?.id) {
                if let savedAddress = viewModel.savedAddress {
                    onSave(savedAddress)
                    dismiss()
                }
            }
        }
    }
}

