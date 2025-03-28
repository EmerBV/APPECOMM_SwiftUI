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
        let trimmed = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("Postal code cannot be empty")
        }
        
        // Un patrón simple para códigos postales, puedes ajustarlo según el país
        let pattern = "^[0-9]{5}(-[0-9]{4})?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        return predicate.evaluate(with: trimmed) ? .valid : .invalid("Please enter a valid postal code")
    }
    
    func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("Phone number cannot be empty")
        }
        
        // Un patrón simple para números de teléfono, puedes ajustarlo según el país
        let pattern = "^[+]?[(]?[0-9]{3}[)]?[-\\s.]?[0-9]{3}[-\\s.]?[0-9]{4,6}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        return predicate.evaluate(with: trimmed) ? .valid : .invalid("Please enter a valid phone number")
    }
    
    func validateCreditCardNumber(_ cardNumber: String) -> ValidationResult {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        
        guard !cleaned.isEmpty else {
            return .invalid("Card number cannot be empty")
        }
        
        // Verificar que solo contenga dígitos
        guard cleaned.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return .invalid("Card number should contain only digits")
        }
        
        // Longitud válida (la mayoría de tarjetas tienen 16 dígitos)
        guard (13...19).contains(cleaned.count) else {
            return .invalid("Card number should be between 13 and 19 digits")
        }
        
        // Implementación del algoritmo de Luhn (validación de checksum)
        var sum = 0
        let reversedCharacters = cleaned.reversed().map { String($0) }
        
        for (index, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else {
                return .invalid("Invalid card number")
            }
            
            // Para índices pares (comenzando desde 0), simplemente sumamos el dígito
            if index % 2 == 0 {
                sum += digit
            } else {
                // Para índices impares, multiplicamos por 2 y sumamos los dígitos del resultado
                let doubledDigit = digit * 2
                sum += doubledDigit > 9 ? doubledDigit - 9 : doubledDigit
            }
        }
        
        // El número es válido si la suma es divisible por 10
        return sum % 10 == 0 ? .valid : .invalid("Invalid card number")
    }
    
    func validateExpiryDate(_ date: String) -> ValidationResult {
        let cleaned = date.replacingOccurrences(of: "/", with: "")
        
        guard !cleaned.isEmpty else {
            return .invalid("Expiry date cannot be empty")
        }
        
        guard cleaned.count == 4, cleaned.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return .invalid("Expiry date should be in MM/YY format")
        }
        
        let monthString = String(cleaned.prefix(2))
        let yearString = String(cleaned.suffix(2))
        
        guard let month = Int(monthString), let year = Int(yearString) else {
            return .invalid("Invalid expiry date format")
        }
        
        // Validar mes (1-12)
        guard (1...12).contains(month) else {
            return .invalid("Month should be between 1 and 12")
        }
        
        // Validar que no esté expirada
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if year < currentYear || (year == currentYear && month < currentMonth) {
            return .invalid("Card has expired")
        }
        
        return .valid
    }
    
    func validateCVV(_ cvv: String) -> ValidationResult {
        let trimmed = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("CVV cannot be empty")
        }
        
        // Validar que solo contenga dígitos
        guard trimmed.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return .invalid("CVV should contain only digits")
        }
        
        // Validar longitud (3 o 4 dígitos)
        guard [3, 4].contains(trimmed.count) else {
            return .invalid("CVV should be 3 or 4 digits")
        }
        
        return .valid
    }
    
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            return .invalid("Email cannot be empty")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .invalid("Please enter a valid email address")
        }
        
        return .valid
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .invalid("Password cannot be empty")
        }
        
        guard password.count >= 6 else {
            return .invalid("Password must be at least 6 characters")
        }
        
        return .valid
    }
    
    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid("Name cannot be empty")
        }
        
        guard trimmedName.count >= 2 else {
            return .invalid("Name must be at least 2 characters")
        }
        
        return .valid
    }
    
    func validateFullName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid("Full name cannot be empty")
        }
        
        // Verifica que haya al menos un espacio (nombre y apellido)
        guard trimmedName.contains(" ") else {
            return .invalid("Please enter both first and last name")
        }
        
        guard trimmedName.count >= 5 else {
            return .invalid("Full name must be at least 5 characters")
        }
        
        return .valid
    }
}

