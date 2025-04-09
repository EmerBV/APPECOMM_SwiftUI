//
//  String+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation

extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    var toDouble: Double {
        return Double(self) ?? 0
    }
    
    var toInt: Int {
        return Int(self) ?? 0
    }
    
    var toPercentage: String {
        return self.isEmpty ? "-" : self + "%"
    }
    
    var isNumber: String {
        return self.filter { ("0"..."9").contains($0) }
    }
    
    func formattedCreditCardNumber() -> String {
        let clean = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var result = ""
        
        for (index, char) in clean.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result += String(char)
        }
        
        return result
    }
    
    func formattedPhoneNumber() -> String {
        let clean = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard clean.count > 0 else { return "" }
        
        let area = String(clean.prefix(3))
        var body = ""
        var suffix = ""
        
        if clean.count > 3 {
            body = String(clean.dropFirst(3).prefix(3))
        }
        
        if clean.count > 6 {
            suffix = String(clean.dropFirst(6).prefix(4))
        }
        
        var result = "(\(area)"
        if body.count > 0 {
            result += ") \(body)"
        }
        
        if suffix.count > 0 {
            result += "-\(suffix)"
        }
        
        return result
    }
    
    func base64UrlDecoded() -> Data? {
        // Ajustar el padding para base64
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        return Data(base64Encoded: base64)
    }
}
