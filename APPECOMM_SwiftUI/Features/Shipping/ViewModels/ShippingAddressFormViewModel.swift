//
//  ShippingAddressFormViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 4/4/25.
//

import Foundation
import Combine

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
    
    // Inicializa el formulario directamente en el constructor
    func initializeForm(with address: ShippingDetails) {
        Logger.debug("Initializing form with address: \(address.id ?? 0)")
        
        // Inicializar valores del formulario desde la dirección
        form.fullName = address.fullName ?? ""
        form.address = address.address ?? ""
        form.city = address.city ?? ""
        form.state = address.state ?? ""
        form.postalCode = address.postalCode ?? ""
        form.country = address.country ?? ""
        form.phoneNumber = address.phoneNumber ?? ""
        form.isDefaultAddress = address.isDefault
        
        // Establecer estados de validación inicial
        form.isFullNameValid = !form.fullName.isEmpty
        form.isAddressValid = !form.address.isEmpty
        form.isCityValid = !form.city.isEmpty
        form.isStateValid = !form.state.isEmpty
        form.isPostalCodeValid = !form.postalCode.isEmpty
        form.isCountryValid = !form.country.isEmpty
        form.isPhoneNumberValid = !form.phoneNumber.isEmpty
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
    
    func validateField(_ field: FieldType) {
        switch field {
        case .fullName:
            let result = validator.validateFullName(form.fullName)
            if case .valid = result {
                form.isFullNameValid = true
                form.fullNameError = nil
            } else if case .invalid(let message) = result {
                form.isFullNameValid = false
                form.fullNameError = message
            }
            
        case .phoneNumber:
            let result = validator.validatePhoneNumber(form.phoneNumber)
            if case .valid = result {
                form.isPhoneNumberValid = true
                form.phoneNumberError = nil
            } else if case .invalid(let message) = result {
                form.isPhoneNumberValid = false
                form.phoneNumberError = message
            }
            
        case .address:
            let result = validator.validateAddress(form.address)
            if case .valid = result {
                form.isAddressValid = true
                form.addressError = nil
            } else if case .invalid(let message) = result {
                form.isAddressValid = false
                form.addressError = message
            }
            
        case .city:
            let result = validator.validateName(form.city)
            if case .valid = result {
                form.isCityValid = true
                form.cityError = nil
            } else if case .invalid(let message) = result {
                form.isCityValid = false
                form.cityError = message
            }
            
        case .state:
            let result = validator.validateName(form.state)
            if case .valid = result {
                form.isStateValid = true
                form.stateError = nil
            } else if case .invalid(let message) = result {
                form.isStateValid = false
                form.stateError = message
            }
            
        case .postalCode:
            let result = validator.validatePostalCode(form.postalCode)
            if case .valid = result {
                form.isPostalCodeValid = true
                form.postalCodeError = nil
            } else if case .invalid(let message) = result {
                form.isPostalCodeValid = false
                form.postalCodeError = message
            }
            
        case .country:
            let result = validator.validateName(form.country)
            if case .valid = result {
                form.isCountryValid = true
                form.countryError = nil
            } else if case .invalid(let message) = result {
                form.isCountryValid = false
                form.countryError = message
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
                Logger.debug("Updating existing address: \(existingAddress)")
                // Update existing address
                let request = form.toRequest(id: existingAddress)
                result = try await shippingRepository.updateShippingAddress(userId: userId, details: request)
                    .async()
                
                // Mostrar mensaje de éxito para actualización
                successMessage = "Address updated successfully"
            } else {
                Logger.debug("Creating new address")
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
            Logger.error("Error saving address: \(error)")
        }
        
        isLoading = false
        return false
    }
}
