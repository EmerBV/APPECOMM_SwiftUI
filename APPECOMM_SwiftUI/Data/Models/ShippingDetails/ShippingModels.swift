//
//  ShippingModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

struct ShippingDetails: Codable, Equatable, Identifiable {
    let id: Int?
    let address: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let phoneNumber: String?
    let fullName: String?
    let isDefault: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case city
        case state
        case postalCode = "postalCode"
        case country
        case phoneNumber = "phoneNumber"
        case fullName = "fullName"
        case isDefault = "isDefault"
    }
}

/// Form model for shipping details with validation
struct ShippingDetailsForm {
    var fullName: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = ""
    var phoneNumber: String = ""
    var isDefaultAddress: Bool? = false
    
    // Validation states
    var isFullNameValid: Bool = false
    var isAddressValid: Bool = false
    var isCityValid: Bool = false
    var isStateValid: Bool = false
    var isPostalCodeValid: Bool = false
    var isCountryValid: Bool = false
    var isPhoneNumberValid: Bool = false
    
    // Validation error messages
    var fullNameError: String?
    var addressError: String?
    var cityError: String?
    var stateError: String?
    var postalCodeError: String?
    var countryError: String?
    var phoneNumberError: String?
    
    var isValid: Bool {
        return isFullNameValid &&
        isAddressValid &&
        isCityValid &&
        isStateValid &&
        isPostalCodeValid &&
        isCountryValid &&
        isPhoneNumberValid
    }
    
    /// Initialize with default empty values
    init() {
        // Default initializer with empty values
    }
    
    /// Initialize with shipping details response
    init(from details: ShippingDetails) {
        self.fullName = details.fullName ?? ""
        self.address = details.address ?? ""
        self.city = details.city ?? ""
        self.state = details.state ?? ""
        self.postalCode = details.postalCode ?? ""
        self.country = details.country ?? ""
        self.phoneNumber = details.phoneNumber ?? ""
        self.isDefaultAddress = details.isDefault ?? false
        
        // Set all fields as valid since they come from validated data
        self.isFullNameValid = !fullName.isEmpty
        self.isAddressValid = !address.isEmpty
        self.isCityValid = !city.isEmpty
        self.isStateValid = !state.isEmpty
        self.isPostalCodeValid = !postalCode.isEmpty
        self.isCountryValid = !country.isEmpty
        self.isPhoneNumberValid = !phoneNumber.isEmpty
    }
    
    /// Convert to ShippingDetailsRequest for API calls
    func toRequest(id: Int? = nil) -> ShippingDetailsRequest {
        return ShippingDetailsRequest(
            id: id,
            address: address,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country,
            phoneNumber: phoneNumber,
            fullName: fullName,
            isDefault: isDefaultAddress ?? false
        )
    }
    
    /// Validate all fields
    mutating func validateAll(validator: InputValidatorProtocol = InputValidator()) {
        // Para cada campo, asegurarse de que se valide correctamente
        
        // Validar nombre completo si no está vacío
        if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let nameResult = validator.validateFullName(fullName)
            switch nameResult {
            case .valid:
                isFullNameValid = true
                fullNameError = nil
            case .invalid(let message):
                isFullNameValid = false
                fullNameError = message
            }
        } else {
            isFullNameValid = false
            fullNameError = "Full name is required"
        }
        
        // Validar dirección si no está vacía
        if !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let addressResult = validator.validateAddress(address)
            switch addressResult {
            case .valid:
                isAddressValid = true
                addressError = nil
            case .invalid(let message):
                isAddressValid = false
                addressError = message
            }
        } else {
            isAddressValid = false
            addressError = "Address is required"
        }
        
        // Validar ciudad si no está vacía
        if !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cityResult = validator.validateName(city)
            switch cityResult {
            case .valid:
                isCityValid = true
                cityError = nil
            case .invalid(let message):
                isCityValid = false
                cityError = message
            }
        } else {
            isCityValid = false
            cityError = "City is required"
        }
        
        // Validar estado si no está vacío
        if !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let stateResult = validator.validateName(state)
            switch stateResult {
            case .valid:
                isStateValid = true
                stateError = nil
            case .invalid(let message):
                isStateValid = false
                stateError = message
            }
        } else {
            isStateValid = false
            stateError = "State is required"
        }
        
        // Validar código postal si no está vacío
        if !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let postalCodeResult = validator.validatePostalCode(postalCode)
            switch postalCodeResult {
            case .valid:
                isPostalCodeValid = true
                postalCodeError = nil
            case .invalid(let message):
                isPostalCodeValid = false
                postalCodeError = message
            }
        } else {
            isPostalCodeValid = false
            postalCodeError = "Postal code is required"
        }
        
        // Validar país si no está vacío
        if !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let countryResult = validator.validateName(country)
            switch countryResult {
            case .valid:
                isCountryValid = true
                countryError = nil
            case .invalid(let message):
                isCountryValid = false
                countryError = message
            }
        } else {
            isCountryValid = false
            countryError = "Country is required"
        }
        
        // Validar número de teléfono si no está vacío
        if !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let phoneResult = validator.validatePhoneNumber(phoneNumber)
            switch phoneResult {
            case .valid:
                isPhoneNumberValid = true
                phoneNumberError = nil
            case .invalid(let message):
                isPhoneNumberValid = false
                phoneNumberError = message
            }
        } else {
            isPhoneNumberValid = false
            phoneNumberError = "Phone number is required"
        }
    }
    
    /// Reset all fields to empty and invalidate them
    mutating func reset() {
        fullName = ""
        address = ""
        city = ""
        state = ""
        postalCode = ""
        country = ""
        phoneNumber = ""
        isDefaultAddress = false
        
        isFullNameValid = false
        isAddressValid = false
        isCityValid = false
        isStateValid = false
        isPostalCodeValid = false
        isCountryValid = false
        isPhoneNumberValid = false
        
        fullNameError = nil
        addressError = nil
        cityError = nil
        stateError = nil
        postalCodeError = nil
        countryError = nil
        phoneNumberError = nil
    }
}
