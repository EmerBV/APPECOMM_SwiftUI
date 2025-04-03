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
        case postalCode = "postal_code"
        case country
        case phoneNumber = "phone_number"
        case fullName = "full_name"
        case isDefault = "is_default"
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
    var isDefaultAddress: Bool? = false // Nueva propiedad para marcar como predeterminada
    
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
        return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Initialize with default empty values
    init() {
        // Default initializer with empty values
    }
    
    /// Initialize with shipping details response
    init(from details: ShippingDetailsResponse) {
        self.fullName = details.fullName ?? ""
        self.address = details.address
        self.city = details.city
        self.state = details.state ?? ""
        self.postalCode = details.postalCode
        self.country = details.country
        self.phoneNumber = details.phoneNumber ?? ""
        self.isDefaultAddress = details.isDefault
        
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
    func toRequest() -> ShippingDetailsRequest {
        return ShippingDetailsRequest(
            address: address,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country,
            phoneNumber: phoneNumber,
            fullName: fullName,
            isDefault: isDefaultAddress
        )
    }
    
    /// Validate all fields
    mutating func validateAll(validator: InputValidatorProtocol = InputValidator()) {
        // Para nombre completo
        let nameResult = validator.validateFullName(fullName)
        switch nameResult {
        case .valid:
            isFullNameValid = true
            fullNameError = nil
        case .invalid(let message):
            isFullNameValid = false
            fullNameError = message
        }
        
        // Para dirección
        let addressResult = validator.validateAddress(address)
        switch addressResult {
        case .valid:
            isAddressValid = true
            addressError = nil
        case .invalid(let message):
            isAddressValid = false
            addressError = message
        }
        
        // Para ciudad
        let cityResult = validator.validateName(city)
        switch cityResult {
        case .valid:
            isCityValid = true
            cityError = nil
        case .invalid(let message):
            isCityValid = false
            cityError = message
        }
        
        // Para estado
        let stateResult = validator.validateName(state)
        switch stateResult {
        case .valid:
            isStateValid = true
            stateError = nil
        case .invalid(let message):
            isStateValid = false
            stateError = message
        }
        
        // Para código postal
        let postalCodeResult = validator.validatePostalCode(postalCode)
        switch postalCodeResult {
        case .valid:
            isPostalCodeValid = true
            postalCodeError = nil
        case .invalid(let message):
            isPostalCodeValid = false
            postalCodeError = message
        }
        
        // Para país
        let countryResult = validator.validateName(country)
        switch countryResult {
        case .valid:
            isCountryValid = true
            countryError = nil
        case .invalid(let message):
            isCountryValid = false
            countryError = message
        }
        
        // Para número de teléfono
        let phoneResult = validator.validatePhoneNumber(phoneNumber)
        switch phoneResult {
        case .valid:
            isPhoneNumberValid = true
            phoneNumberError = nil
        case .invalid(let message):
            isPhoneNumberValid = false
            phoneNumberError = message
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
