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
    func validateFullName(_ fullName: String) -> ValidationResult
    func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult
    func validatePostalCode(_ postalCode: String) -> ValidationResult
    func validateAddress(_ address: String) -> ValidationResult
    func validateCreditCardNumber(_ cardNumber: String) -> ValidationResult
    func validateExpiryDate(_ expiryDate: String) -> ValidationResult
    func validateCVV(_ cvv: String) -> ValidationResult
}

struct InputValidator: InputValidatorProtocol {
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            return .invalid(NSLocalizedString("error_email_empty", comment: "Error: Email is empty"))
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .invalid(NSLocalizedString("error_email_invalid", comment: "Error: Email is invalid"))
        }
        
        return .valid
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .invalid(NSLocalizedString("error_password_empty", comment: "Error: Password is empty"))
        }
        
        if password.count < 6 {
            return .invalid(NSLocalizedString("error_password_short", comment: "Error: Password is too short"))
        }
        
        return .valid
    }
    
    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid(NSLocalizedString("error_name_empty", comment: "Error: Name is empty"))
        }
        
        return .valid
    }
    
    func validateFullName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            // Si está en el Localize
            //return .invalid(NSLocalizedString("error_fullname_empty", comment: "Error: Full name is empty"))
            return .invalid("Full name cannot be empty")
        }
        
        // Verificar que tenga al menos dos partes (nombre y apellido)
        let nameParts = trimmedName.components(separatedBy: " ").filter { !$0.isEmpty }
        if nameParts.count < 2 {
            return .invalid("Please enter both first and last name")
        }
        
        // Verificar la longitud mínima de cada parte
        for part in nameParts {
            if part.count < 2 {
                return .invalid("Each part of the name should be at least 2 characters")
            }
        }
        
        return .valid
    }
    
    func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Eliminar caracteres no numéricos para la validación
        let digitsOnly = trimmedPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Verificar longitud mínima (varía según el país)
        if digitsOnly.count < 7 {
            return .invalid("Phone number is too short")
        }
        
        // Verificar longitud máxima
        if digitsOnly.count > 15 {
            return .invalid("Phone number is too long")
        }
        
        // Permite números, espacios, +, -, y paréntesis
        // Si quiero permitir esto descomentar este bloque y comentar el bloque de arriba
        /*
         let phoneRegex = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s\\./0-9]*$"
         let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
         
         if !phonePredicate.evaluate(with: trimmedPhone) {
         return .invalid(NSLocalizedString("error_phone_invalid", comment: "Error: Phone number is invalid"))
         }
         */
        
        return .valid
    }
    
    func validatePostalCode(_ postalCode: String) -> ValidationResult {
        let trimmedPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedPostalCode.isEmpty {
            return .invalid("Postal code cannot be empty")
        }
        
        // Validación básica - en una app real, se validaría según el país
        if trimmedPostalCode.count < 3 || trimmedPostalCode.count > 10 {
            return .invalid("Invalid postal code format")
        }
        
        return .valid
    }
    
    // Validar dirección completa
    func validateAddress(_ address: String) -> ValidationResult {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAddress.isEmpty {
            return .invalid("Address cannot be empty")
        }
        
        if trimmedAddress.count < 5 {
            return .invalid("Address is too short")
        }
        
        if trimmedAddress.count > 100 {
            return .invalid("Address is too long")
        }
        
        return .valid
    }
    
    func validateCreditCardNumber(_ cardNumber: String) -> ValidationResult {
        let trimmedNumber = cardNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedNumber.isEmpty {
            return .invalid(NSLocalizedString("error_card_number_empty", comment: "Error: Card number is empty"))
        }
        
        // Verificar que sean solo dígitos
        let numberRegex = "^[0-9]{13,19}$"
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        
        if !numberPredicate.evaluate(with: trimmedNumber) {
            return .invalid(NSLocalizedString("error_card_number_invalid", comment: "Error: Card number is invalid"))
        }
        
        // Algoritmo de Luhn para validar tarjetas de crédito
        var sum = 0
        let reversedCharacters = trimmedNumber.reversed().map { String($0) }
        
        for (index, digit) in reversedCharacters.enumerated() {
            guard let digitValue = Int(digit) else { continue }
            
            if index % 2 == 1 {
                let doubledValue = digitValue * 2
                sum += doubledValue > 9 ? doubledValue - 9 : doubledValue
            } else {
                sum += digitValue
            }
        }
        
        if sum % 10 != 0 {
            return .invalid(NSLocalizedString("error_card_number_invalid", comment: "Error: Card number is invalid"))
        }
        
        return .valid
    }
    
    func validateExpiryDate(_ expiryDate: String) -> ValidationResult {
        let trimmedDate = expiryDate.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedDate.isEmpty {
            return .invalid(NSLocalizedString("error_expiry_date_empty", comment: "Error: Expiry date is empty"))
        }
        
        // Formato esperado: MM/YY
        let dateRegex = "^(0[1-9]|1[0-2])\\/([0-9]{2})$"
        let datePredicate = NSPredicate(format: "SELF MATCHES %@", dateRegex)
        
        if !datePredicate.evaluate(with: trimmedDate) {
            return .invalid(NSLocalizedString("error_expiry_date_format", comment: "Error: Expiry date format should be MM/YY"))
        }
        
        let components = trimmedDate.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]) else {
            return .invalid(NSLocalizedString("error_expiry_date_invalid", comment: "Error: Expiry date is invalid"))
        }
        
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if year < currentYear || (year == currentYear && month < currentMonth) {
            return .invalid(NSLocalizedString("error_expiry_date_past", comment: "Error: Card has expired"))
        }
        
        return .valid
    }
    
    func validateCVV(_ cvv: String) -> ValidationResult {
        let trimmedCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedCVV.isEmpty {
            return .invalid(NSLocalizedString("error_cvv_empty", comment: "Error: CVV is empty"))
        }
        
        let cvvRegex = "^[0-9]{3,4}$"
        let cvvPredicate = NSPredicate(format: "SELF MATCHES %@", cvvRegex)
        
        if !cvvPredicate.evaluate(with: trimmedCVV) {
            return .invalid(NSLocalizedString("error_cvv_invalid", comment: "Error: CVV should be 3 or 4 digits"))
        }
        
        return .valid
    }
}

