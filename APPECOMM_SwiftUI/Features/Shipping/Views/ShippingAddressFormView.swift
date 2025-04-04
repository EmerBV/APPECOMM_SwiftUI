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
    @StateObject private var viewModel: ShippingAddressFormViewModel
    
    init(userId: Int, address: ShippingDetails? = nil, onSave: @escaping (ShippingDetails) -> Void) {
        self.userId = userId
        self.address = address
        self.onSave = onSave
        
        // Inicializar el ViewModel a través de la inyección de dependencias
        let dependencies = DependencyInjector.shared
        let shippingRepository = dependencies.resolve(ShippingRepositoryProtocol.self)
        let validator = dependencies.resolve(InputValidatorProtocol.self)
        
        _viewModel = StateObject(wrappedValue: ShippingAddressFormViewModel(
            shippingRepository: shippingRepository,
            validator: validator
        ))
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
            .onAppear {
                if let existingAddress = address {
                    viewModel.populateForm(with: existingAddress)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
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
                        // Auto-ocultar después de 2 segundos
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
                // Si el guardado fue exitoso, obtenemos la dirección guardada
                if let savedAddress = viewModel.savedAddress {
                    onSave(savedAddress)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - ViewModel

class ShippingAddressFormViewModel: ObservableObject {
    @Published var form = ShippingDetailsForm()
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage: String?
    @Published var showingSuccess = false
    @Published var successMessage: String?
    @Published var savedAddress: ShippingDetails?
    
    private let shippingRepository: ShippingRepositoryProtocol
    private let validator: InputValidatorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Campos a validar
    enum FieldType {
        case fullName, phoneNumber, address, city, state, postalCode, country
    }
    
    init(shippingRepository: ShippingRepositoryProtocol, validator: InputValidatorProtocol) {
        self.shippingRepository = shippingRepository
        self.validator = validator
    }
    
    var isValid: Bool {
        return form.isFullNameValid &&
        form.isAddressValid &&
        form.isCityValid &&
        form.isStateValid &&
        form.isPostalCodeValid &&
        form.isCountryValid &&
        form.isPhoneNumberValid
    }
    
    func populateForm(with address: ShippingDetails) {
        // Crear un ShippingDetailsForm a partir de ShippingDetails
        form = ShippingDetailsForm(from: address)
        
        // Validar todos los campos después de la carga
        validateAllFields()
    }
    
    func validateField(_ field: FieldType) {
        switch field {
        case .fullName:
            let result = validator.validateFullName(form.fullName)
            // Corregido: Verifica si el resultado es válido usando el patrón de casos
            if case .valid = result {
                form.isFullNameValid = true
            } else {
                form.isFullNameValid = false
            }
        case .phoneNumber:
            let result = validator.validatePhoneNumber(form.phoneNumber)
            if case .valid = result {
                form.isPhoneNumberValid = true
            } else {
                form.isPhoneNumberValid = false
            }
        case .address:
            let result = validator.validateAddress(form.address)
            if case .valid = result {
                form.isAddressValid = true
            } else {
                form.isAddressValid = false
            }
        case .city:
            let result = validator.validateName(form.city)
            if case .valid = result {
                form.isCityValid = true
            } else {
                form.isCityValid = false
            }
        case .state:
            let result = validator.validateName(form.state)
            if case .valid = result {
                form.isStateValid = true
            } else {
                form.isStateValid = false
            }
        case .postalCode:
            let result = validator.validatePostalCode(form.postalCode)
            if case .valid = result {
                form.isPostalCodeValid = true
            } else {
                form.isPostalCodeValid = false
            }
        case .country:
            let result = validator.validateName(form.country)
            if case .valid = result {
                form.isCountryValid = true
            } else {
                form.isCountryValid = false
            }
        }
    }
    
    func validateAllFields() {
        validateField(.fullName)
        validateField(.phoneNumber)
        validateField(.address)
        validateField(.city)
        validateField(.state)
        validateField(.postalCode)
        validateField(.country)
    }
    
    @MainActor
    func saveAddress(userId: Int, existingAddressId: Int?) async -> Bool {
        validateAllFields()
        
        guard isValid else {
            errorMessage = "Please fill in all required fields correctly"
            showingError = true
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result: ShippingDetails?
            
            if let existingAddress = existingAddressId {
                // Update existing address
                let request = form.toRequest(id: existingAddress)
                result = try await shippingRepository.updateShippingAddress(userId: userId, details: request)
                    .async()
                
                // Mostrar mensaje de éxito para actualización
                successMessage = "Address updated successfully"
            } else {
                // Create new address
                result = try await shippingRepository.createShippingAddress(userId: userId, details: form)
                    .async()
                
                // Mostrar mensaje de éxito para creación
                successMessage = "Address added successfully"
            }
            
            if let address = result {
                isLoading = false
                savedAddress = address
                showingSuccess = true
                
                return true
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
        return false
    }
}


