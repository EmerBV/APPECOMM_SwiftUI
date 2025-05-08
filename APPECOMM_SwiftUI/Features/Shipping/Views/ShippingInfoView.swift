//
//  ShippingInfoView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct ShippingInfoView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @FocusState private var focusedField: ShippingField?
    @State private var showingAddressSelector = false
    @Environment(\.dismiss) private var dismiss
    
    enum ShippingField {
        case fullName
        case address
        case city
        case state
        case postalCode
        case country
        case phoneNumber
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Content: address selector, existing details, or form
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.shippingAddresses.isEmpty && !viewModel.isAddingNewAddress {
                            // Mostrar selección de dirección
                            existingAddressesView
                        } else {
                            // Mostrar formulario
                            shippingFormView
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                // Añadir padding inferior para evitar que el contenido quede detrás del botón
                .padding(.bottom, 80)
            }
            
            // Botón fijo en la parte inferior
            VStack {
                PrimaryButton(
                    title: "continue_label".localized,
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.hasExistingShippingDetails || viewModel.selectedAddress != nil || viewModel.shippingDetailsForm.isValid
                ) {
                    focusedField = nil
                    if viewModel.isAddingNewAddress {
                        viewModel.createNewShippingAddress()
                    } else if viewModel.selectedAddress != nil {
                        // Si ya hay una dirección seleccionada, simplemente avanzamos
                        viewModel.proceedToNextStep()
                    } else if viewModel.hasExistingShippingDetails && viewModel.existingShippingDetails != nil {
                        // Si hay dirección existente pero no seleccionada, usamos esa
                        viewModel.selectedAddress = viewModel.existingShippingDetails
                        viewModel.proceedToNextStep()
                    } else {
                        // En otro caso, validamos y guardamos
                        viewModel.validateShippingForm()
                        if viewModel.shippingDetailsForm.isValid {
                            viewModel.saveShippingDetails()
                        } else {
                            viewModel.errorMessage = "please_fill_in".localized
                            viewModel.showError = true
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
        }
        .navigationTitle("shipping_address_label".localized)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    
                    Button("next_label".localized) {
                        moveToNextField()
                    }
                    
                    Button("done_label".localized) {
                        focusedField = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddressSelector) {
            ShippingAddressSelectorView(viewModel: viewModel)
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("error".localized),
                message: Text(viewModel.errorMessage ?? "unknown_error".localized),
                dismissButton: .default(Text("ok".localized))
            )
        }
        .onAppear {
            // Cargar direcciones de envío al aparecer la vista
            if viewModel.shippingAddresses.isEmpty {
                viewModel.loadUserAddress()
            }
        }
    }
    
    // MARK: - Content Views
    
    /// Vista para selección de direcciones existentes
    private var existingAddressesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabecera con texto descriptivo y botón de selección
            HStack {
                Text("select_shipping_address".localized)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAddressSelector = true
                }) {
                    Text("change_label".localized)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            // Mostrar la dirección seleccionada
            if let selectedId = viewModel.selectedShippingAddressId,
               let address = viewModel.shippingAddresses.first(where: { $0.id == selectedId }) {
                VStack(alignment: .leading, spacing: 6) {
                    if let fullName = address.fullName, !fullName.isEmpty {
                        Text(fullName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(address.address ?? "")
                        .font(.subheadline)
                    
                    Text("\(address.city ?? ""), \(address.state ?? "") \(address.postalCode ?? "")")
                        .font(.subheadline)
                    
                    Text(address.country ?? "")
                        .font(.subheadline)
                    
                    if let phoneNumber = address.phoneNumber, !phoneNumber.isEmpty {
                        Text(phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            } else {
                // Mensaje si no hay dirección seleccionada
                Text("no_shipping_address_selected".localized)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
            }
            
            // Botón para agregar nueva dirección
            Button(action: {
                viewModel.isAddingNewAddress = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("add_new_address".localized)
                }
                .foregroundColor(.blue)
                .padding(.vertical, 8)
            }
        }
    }
    
    /// Vista de formulario para nueva dirección
    private var shippingFormView: some View {
        VStack(spacing: 16) {
            // Header con botón para cancelar
            if !viewModel.shippingAddresses.isEmpty {
                HStack {
                    Text("add_new_address".localized)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.isAddingNewAddress = false
                    }) {
                        Text("cancel".localized)
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Text("add_shipping_address".localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Campos del formulario
            CustomTextField(
                title: "full_name".localized,
                placeholder: "John Doe",
                type: .regular,
                state: viewModel.shippingDetailsForm.isFullNameValid ?
                    .valid :
                    (viewModel.shippingDetailsForm.fullName.isEmpty ? .normal : .error("fullname_is_required".localized)),
                text: Binding(
                    get: { viewModel.shippingDetailsForm.fullName },
                    set: {
                        viewModel.shippingDetailsForm.fullName = $0
                        viewModel.shippingDetailsForm.isFullNameValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .focused($focusedField, equals: .fullName)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .address
            }
            
            CustomTextField(
                title: "address".localized,
                placeholder: "123 Main St",
                type: .regular,
                state: viewModel.shippingDetailsForm.isAddressValid ? .valid : .normal,
                text: Binding(
                    get: { viewModel.shippingDetailsForm.address },
                    set: {
                        viewModel.shippingDetailsForm.address = $0
                        viewModel.shippingDetailsForm.isAddressValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .focused($focusedField, equals: .address)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .city
            }
            
            HStack(spacing: 12) {
                CustomTextField(
                    title: "city".localized,
                    placeholder: "New York",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isCityValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.city },
                        set: {
                            viewModel.shippingDetailsForm.city = $0
                            viewModel.shippingDetailsForm.isCityValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .city)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .state
                }
                
                CustomTextField(
                    title: "state_province".localized,
                    placeholder: "NY",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isStateValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.state },
                        set: {
                            viewModel.shippingDetailsForm.state = $0
                            viewModel.shippingDetailsForm.isStateValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .state)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .postalCode
                }
            }
            
            HStack(spacing: 12) {
                CustomTextField(
                    title: "postal_code".localized,
                    placeholder: "10001",
                    type: .numeric,
                    state: viewModel.shippingDetailsForm.isPostalCodeValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.postalCode },
                        set: {
                            viewModel.shippingDetailsForm.postalCode = $0
                            viewModel.shippingDetailsForm.isPostalCodeValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .postalCode)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .country
                }
                
                CustomTextField(
                    title: "country".localized,
                    placeholder: "United States",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isCountryValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.country },
                        set: {
                            viewModel.shippingDetailsForm.country = $0
                            viewModel.shippingDetailsForm.isCountryValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .country)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .phoneNumber
                }
            }
            
            CustomTextField(
                title: "phone_number".localized,
                placeholder: "+1 (555) 123-4567",
                type: .phone,
                state: viewModel.shippingDetailsForm.isPhoneNumberValid ? .valid : .normal,
                text: Binding(
                    get: { viewModel.shippingDetailsForm.phoneNumber },
                    set: {
                        viewModel.shippingDetailsForm.phoneNumber = $0
                        viewModel.shippingDetailsForm.isPhoneNumberValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .focused($focusedField, equals: .phoneNumber)
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
            }
            
            // Opción para establecer como dirección predeterminada
            Toggle("set_as_default_shipping".localized, isOn: Binding(
                get: { viewModel.shippingDetailsForm.isDefaultAddress ?? false },
                set: { viewModel.shippingDetailsForm.isDefaultAddress = $0 }
            ))
            .font(.subheadline)
            .padding(.vertical, 8)
        }
    }
    
    private func moveToNextField() {
        switch focusedField {
        case .fullName:
            focusedField = .address
        case .address:
            focusedField = .city
        case .city:
            focusedField = .state
        case .state:
            focusedField = .postalCode
        case .postalCode:
            focusedField = .country
        case .country:
            focusedField = .phoneNumber
        case .phoneNumber:
            focusedField = nil
        case nil:
            focusedField = nil
        }
    }
}
