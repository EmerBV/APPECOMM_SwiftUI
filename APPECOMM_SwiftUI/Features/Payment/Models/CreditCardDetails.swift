//
//  CreditCardDetails.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation

struct CreditCardDetails {
    var cardNumber: String = ""
    var expiryDate: String = ""
    var cvv: String = ""
    var cardholderName: String = ""
    
    // Validation states
    var isCardNumberValid: Bool = false
    var isExpiryDateValid: Bool = false
    var isCvvValid: Bool = false
    var isCardholderNameValid: Bool = false
    
    // Error messages
    var cardNumberError: String?
    var expiryDateError: String?
    var cvvError: String?
    var cardholderNameError: String?
    
    var isValid: Bool {
        return isCardNumberValid && isExpiryDateValid && isCvvValid && isCardholderNameValid
    }
    
    /// Initialize with default empty values
    init() {
        // Default initializer with empty values
    }
    
    /// Initialize with provided values
    init(cardNumber: String, expiryDate: String, cvv: String, cardholderName: String) {
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.cardholderName = cardholderName
    }
    
    /// Validate all fields
    mutating func validateAll(validator: InputValidatorProtocol = InputValidator()) {
        // Validar número de tarjeta
        let cardNumberResult = validator.validateCreditCardNumber(cardNumber)
        switch cardNumberResult {
        case .valid:
            isCardNumberValid = true
            cardNumberError = nil
        case .invalid(let message):
            isCardNumberValid = false
            cardNumberError = message
        }
        
        // Validar fecha de expiración
        let expiryDateResult = validator.validateExpiryDate(expiryDate)
        switch expiryDateResult {
        case .valid:
            isExpiryDateValid = true
            expiryDateError = nil
        case .invalid(let message):
            isExpiryDateValid = false
            expiryDateError = message
        }
        
        // Validar CVV
        let cvvResult = validator.validateCVV(cvv)
        switch cvvResult {
        case .valid:
            isCvvValid = true
            cvvError = nil
        case .invalid(let message):
            isCvvValid = false
            cvvError = message
        }
        
        // Validar nombre del titular
        let nameResult = validator.validateName(cardholderName)
        switch nameResult {
        case .valid:
            isCardholderNameValid = true
            cardholderNameError = nil
        case .invalid(let message):
            isCardholderNameValid = false
            cardholderNameError = message
        }
    }
    
    /// Reset all fields to empty and invalidate them
    mutating func reset() {
        cardNumber = ""
        expiryDate = ""
        cvv = ""
        cardholderName = ""
        
        isCardNumberValid = false
        isExpiryDateValid = false
        isCvvValid = false
        isCardholderNameValid = false
        
        cardNumberError = nil
        expiryDateError = nil
        cvvError = nil
        cardholderNameError = nil
    }
}
