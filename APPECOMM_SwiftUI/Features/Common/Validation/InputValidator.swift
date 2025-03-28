//
//  InputValidator.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import SwiftUI

enum ValidationResult {
    case valid
    case invalid(String)
}

protocol InputValidatorProtocol {
    func validateEmail(_ email: String) -> ValidationResult
    func validatePassword(_ password: String) -> ValidationResult
    func validateName(_ name: String) -> ValidationResult
    func validateFullName(_ name: String) -> ValidationResult
    func validateCreditCardNumber(_ cardNumber: String) -> ValidationResult
    func validateExpiryDate(_ date: String) -> ValidationResult
    func validateCVV(_ cvv: String) -> ValidationResult
    func validatePostalCode(_ postalCode: String) -> ValidationResult
    func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult
}

final class InputValidator: InputValidatorProtocol {
    func validatePostalCode(_ postalCode: String) -> ValidationResult {
        return .valid
    }
    
    func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        return .valid
    }
    
    func validateCreditCardNumber(_ cardNumber: String) -> ValidationResult {
        return .valid
    }
    
    func validateExpiryDate(_ date: String) -> ValidationResult {
        return .valid
    }
    
    func validateCVV(_ cvv: String) -> ValidationResult {
        return .valid
    }
    
    
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            return .invalid(NSLocalizedString("Email cannot be empty", comment: ""))
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .invalid(NSLocalizedString("Please enter a valid email address", comment: ""))
        }
        
        return .valid
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .invalid(NSLocalizedString("Password cannot be empty", comment: ""))
        }
        
        guard password.count >= 6 else {
            return .invalid(NSLocalizedString("Password must be at least 6 characters", comment: ""))
        }
        
        return .valid
    }
    
    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid("name_empty".localized)
        }
        
        guard trimmedName.count >= 2 else {
            return .invalid("name_too_short".localized)
        }
        
        return .valid
    }
    
    func validateFullName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid("name_empty".localized)
        }
        
        guard trimmedName.count >= 2 else {
            return .invalid("name_too_short".localized)
        }
        
        return .valid
    }
}

