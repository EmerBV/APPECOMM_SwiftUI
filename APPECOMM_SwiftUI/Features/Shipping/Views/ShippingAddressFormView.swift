//
//  ShippingAddressFormView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct ShippingAddressFormView: View {
    // Ambiente y presentación
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ShippingAddressViewModel
    let addressId: Int?
    let isNewAddress: Bool
    
    // Estado local
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(viewModel: ShippingAddressViewModel, addressId: Int? = nil) {
        self.viewModel = viewModel
        self.addressId = addressId
        self.isNewAddress = addressId == nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Datos personales
                Section(header: Text("Información Personal")) {
                    CustomTextField(
                        title: "Nombre Completo",
                        placeholder: "Ingrese su nombre",
                        type: .regular,
                        state: viewModel.form.isFullNameValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.form.fullName },
                            set: {
                                viewModel.form.fullName = $0
                                viewModel.validateField(.fullName)
                            }
                        )
                    )
                    
                    CustomTextField(
                        title: "Teléfono",
                        placeholder: "+1 (555) 123-4567",
                        type: .phone,
                        state: viewModel.form.isPhoneNumberValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.form.phoneNumber },
                            set: {
                                viewModel.form.phoneNumber = $0
                                viewModel.validateField(.phoneNumber)
                            }
                        )
                    )
                    .keyboardType(.phonePad)
                }
                
                // Dirección
                Section(header: Text("Dirección de Envío")) {
                    CustomTextField(
                        title: "Dirección",
                        placeholder: "Ej: Calle Principal 123",
                        type: .regular,
                        state: viewModel.form.isAddressValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.form.address },
                            set: {
                                viewModel.form.address = $0
                                viewModel.validateField(.address)
                            }
                        )
                    )
                    
                    CustomTextField(
                        title: "Ciudad",
                        placeholder: "Ej: Madrid",
                        type: .regular,
                        state: viewModel.form.isCityValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.form.city },
                            set: {
                                viewModel.form.city = $0
                                viewModel.validateField(.city)
                            }
                        )
                    )
                    
                    HStack {
                        CustomTextField(
                            title: "Estado/Provincia",
                            placeholder: "Ej: Madrid",
                            type: .regular,
                            state: viewModel.form.isStateValid ? .valid : .normal,
                            text: Binding(
                                get: { viewModel.form.state },
                                set: {
                                    viewModel.form.state = $0
                                    viewModel.validateField(.state)
                                }
                            )
                        )
                        
                        CustomTextField(
                            title: "Código Postal",
                            placeholder: "Ej: 28001",
                            type: .regular,
                            state: viewModel.form.isPostalCodeValid ? .valid : .normal,
                            text: Binding(
                                get: { viewModel.form.postalCode },
                                set: {
                                    viewModel.form.postalCode = $0
                                    viewModel.validateField(.postalCode)
                                }
                            )
                        )
                        .keyboardType(.numberPad)
                    }
                    
                    CustomTextField(
                        title: "País",
                        placeholder: "Ej: España",
                        type: .regular,
                        state: viewModel.form.isCountryValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.form.country },
                            set: {
                                viewModel.form.country = $0
                                viewModel.validateField(.country)
                            }
                        )
                    )
                }
                
                // Opciones adicionales
                Section {
                    Toggle("Establecer como dirección predeterminada", isOn: Binding(
                        get: { viewModel.form.isDefaultAddress ?? false },
                        set: { viewModel.form.isDefaultAddress = $0 }
                    ))
                }
                
                // Botón de guardado
                Section {
                    Button(action: saveAddress) {
                        HStack {
                            Text(isNewAddress ? "Añadir Dirección" : "Actualizar Dirección")
                                .fontWeight(.semibold)
                            
                            if isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .disabled(!viewModel.form.isValid || isLoading)
                }
            }
            .navigationTitle(isNewAddress ? "Nueva Dirección" : "Editar Dirección")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAddressDetails()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Aviso"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Aceptar")) {
                        if !alertMessage.contains("Error") {
                            dismiss()
                        }
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
        }
    }
    
    private func loadAddressDetails() {
        guard let addressId = addressId, !isNewAddress else {
            // Es una nueva dirección, no hay datos que cargar
            viewModel.resetForm()
            return
        }
        
        // Forzar una carga fresca desde el servidor en lugar de usar datos en caché
        viewModel.loadAddressDetails(addressId: addressId, forceRefresh: true)
    }
    
    private func saveAddress() {
        isLoading = true
        
        if isNewAddress {
            viewModel.createAddress { result in
                isLoading = false
                
                switch result {
                case .success:
                    alertMessage = "Dirección añadida correctamente"
                    showAlert = true
                case .failure(let error):
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } else {
            viewModel.updateAddress(addressId: addressId!) { result in
                isLoading = false
                
                switch result {
                case .success:
                    alertMessage = "Dirección actualizada correctamente"
                    showAlert = true
                case .failure(let error):
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
