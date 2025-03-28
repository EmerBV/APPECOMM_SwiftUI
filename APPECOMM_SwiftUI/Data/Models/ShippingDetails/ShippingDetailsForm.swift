//
//  ShippingDetailsForm.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

/// Form model for shipping details with validation
struct ShippingDetailsForm {
    var fullName: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = ""
    var phoneNumber: String = ""
    
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
        return isFullNameValid && isAddressValid && isCityValid &&
        isStateValid && isPostalCodeValid && isCountryValid && isPhoneNumberValid
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
            fullName: fullName
        )
    }
    
    /// Validate all fields
    mutating func validateAll(validator: InputValidatorProtocol = InputValidator()) {
        // For methods that return ValidationResult
        let nameResult = validator.validateName(fullName)
        switch nameResult {
        case .valid:
            isFullNameValid = true
            fullNameError = nil
        case .invalid(let message):
            isFullNameValid = false
            fullNameError = message
        }
        
        // For methods that return Bool
        isAddressValid = !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        isCityValid = !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        isStateValid = !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        isPostalCodeValid = validator.validatePostalCode(postalCode)
        isCountryValid = !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        isPhoneNumberValid = validator.validatePhoneNumber(phoneNumber)
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
