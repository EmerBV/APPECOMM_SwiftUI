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
                Section(header: Text("contact_info".localized)) {
                    CustomTextField(
                        title: "full_name".localized,
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
                        title: "phone_number".localized,
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
                Section(header: Text("address".localized)) {
                    CustomTextField(
                        title: "street_address".localized,
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
                        title: "city".localized,
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
                        title: "state_province".localized,
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
                        title: "postal_code".localized,
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
                        title: "country".localized,
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
                        Text("set_as_default_address".localized)
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
                            Text("save_address".localized)
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
            .navigationTitle(address == nil ? "add_address".localized : "edit_address".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
            }
            
            .circularLoading(
                isLoading: viewModel.isLoading,
                message: "loading".localized,
                strokeColor: .blue,
                backgroundColor: .gray.opacity(0.1),
                showBackdrop: true,
                containerSize: 80,
                logoSize: 50
            )
            
            .alert("error".localized, isPresented: $viewModel.showingError) {
                Button("ok".localized, role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "error_occurred".localized)
            }
            
            .overlay(alignment: .bottom) {
                if viewModel.showingSuccess {
                    SuccessToast(
                        message: viewModel.successMessage ?? "address_saved".localized,
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

