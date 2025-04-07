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
    @State private var showCancelConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    
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
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Shipping Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Content: address selector, existing details, or form
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.shippingAddresses.isEmpty && !viewModel.isAddingNewAddress {
                        // Mostrar selección de dirección
                        existingAddressesView
                    } else {
                        // Mostrar formulario
                        shippingFormView
                    }
                    
                    // Order summary
                    OrderSummaryCard(viewModel: viewModel)
                    
                    // Continue button
                    PrimaryButton(
                        title: "Continue to Payment",
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
                                viewModel.errorMessage = "Please fill in all required fields correctly"
                                viewModel.showError = true
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Shipping Information")
        .toolbar {
            // Botón de cancelación en la barra de navegación
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    showCancelConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    
                    Button("Next") {
                        moveToNextField()
                    }
                    
                    Button("Done") {
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
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("¿Cancelar pedido?", isPresented: $showCancelConfirmation) {
            Button("Continuar con el pedido", role: .cancel) { }
            Button("Cancelar pedido", role: .destructive) {
                // Limpiamos cualquier estado temporal antes de salir
                viewModel.resetCheckoutState()
                // Publicamos una notificación para que se actualice el carrito si es necesario
                NotificationCenter.default.post(name: .refreshCart, object: nil)
                
                // Usamos el NavigationCoordinator para manejar la navegación de manera centralizada
                navigationCoordinator.dismissCurrentView()
                // Notificamos que hay que volver al carrito
                NotificationCenter.default.post(name: .navigateToCartTab, object: nil)
                // También llamamos a dismiss() para cerrar cualquier vista modal
                dismiss()
            }
        } message: {
            Text("Si cancelas ahora, perderás la información introducida y volverás al carrito.")
        }
        .onAppear {
            // Cargar direcciones de envío al aparecer la vista
            if viewModel.shippingAddresses.isEmpty {
                viewModel.loadShippingAddresses()
            }
        }
    }
    
    // MARK: - Content Views
    
    /// Vista para selección de direcciones existentes
    private var existingAddressesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabecera con texto descriptivo y botón de selección
            HStack {
                Text("Shipping Address")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAddressSelector = true
                }) {
                    Text("Change")
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
                Text("No shipping address selected")
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
                    Text("Add New Address")
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
                    Text("Add New Address")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.isAddingNewAddress = false
                    }) {
                        Text("Cancel")
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Text("Add Shipping Address")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Campos del formulario
            CustomTextField(
                title: "Full Name",
                placeholder: "John Doe",
                type: .regular,
                state: viewModel.shippingDetailsForm.isFullNameValid ?
                    .valid :
                    (viewModel.shippingDetailsForm.fullName.isEmpty ? .normal : .error("Name is required")),
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
                title: "Address",
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
                    title: "City",
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
                    title: "State",
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
                    title: "Postal Code",
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
                    title: "Country",
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
                title: "Phone Number",
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
            Toggle("Set as default shipping address", isOn: Binding(
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
