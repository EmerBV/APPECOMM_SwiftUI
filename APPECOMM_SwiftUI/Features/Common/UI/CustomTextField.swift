//
//  CustomTextField.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

enum FieldState {
    case normal
    case valid
    case invalid(String)
    case error(String)
}

struct CustomTextField: View {
    enum TextFieldType {
        case regular
        case secure
        case numeric
        case email
        case phone
    }
    
    let title: String
    let placeholder: String
    let type: TextFieldType
    let state: FieldState
    @Binding var text: String
    var onEditingChanged: ((Bool) -> Void)?
    var onCommit: (() -> Void)?
    @State private var isSecureTextVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .trailing) {
                if type == .secure && isSecureTextVisible {
                    TextField(placeholder, text: $text, onEditingChanged: { isEditing in
                        onEditingChanged?(isEditing)
                    }, onCommit: {
                        onCommit?()
                    })
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                } else if type == .secure {
                    SecureField(placeholder, text: $text) {
                        onCommit?()
                    }
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                } else {
                    TextField(placeholder, text: $text, onEditingChanged: { isEditing in
                        onEditingChanged?(isEditing)
                    }, onCommit: {
                        onCommit?()
                    })
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(type == .regular ? .emailAddress : .default)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                }
                
                if type == .secure {
                    Button(action: {
                        isSecureTextVisible.toggle()
                    }) {
                        Image(systemName: isSecureTextVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
                }
            }
            
            if case .invalid(let errorMessage) = state {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
    
    private var borderColor: Color {
        switch state {
        case .normal:
            return Color(.systemGray4)
        case .valid:
            return .green
        case .invalid:
            return .red
        case .error(_):
            return .red
        }
    }
}

/*
 enum TextFieldType {
 case regular
 case secure
 case numeric
 case email
 case phone
 }
 
 enum TextFieldState {
 case normal
 case error(String)
 case valid
 }
 
 struct CustomTextField: View {
 let title: String
 let placeholder: String
 let type: TextFieldType
 var state: TextFieldState = .normal
 @Binding var text: String
 
 // Optional binding for ValidationResult
 var validationResult: ValidationResult? = nil
 
 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 // Title
 Text(title)
 .font(.subheadline)
 .fontWeight(.medium)
 .foregroundColor(foregroundColor)
 
 // Text field
 Group {
 switch type {
 case .regular:
 TextField(placeholder, text: $text)
 .textContentType(.none)
 case .secure:
 SecureField(placeholder, text: $text)
 .textContentType(.password)
 case .numeric:
 TextField(placeholder, text: $text)
 .keyboardType(.numberPad)
 .textContentType(.none)
 case .email:
 TextField(placeholder, text: $text)
 .keyboardType(.emailAddress)
 .textContentType(.emailAddress)
 .autocapitalization(.none)
 .autocorrectionDisabled()
 case .phone:
 TextField(placeholder, text: $text)
 .keyboardType(.phonePad)
 .textContentType(.telephoneNumber)
 }
 }
 .padding()
 .background(
 RoundedRectangle(cornerRadius: 8)
 .stroke(borderColor, lineWidth: 1)
 .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
 )
 
 // Error message
 if case .error(let message) = state {
 Text(message)
 .font(.caption)
 .foregroundColor(.red)
 .padding(.leading, 4)
 }
 
 // Handle ValidationResult if provided
 if let validationResult = validationResult, case .invalid(let message) = validationResult {
 Text(message)
 .font(.caption)
 .foregroundColor(.red)
 .padding(.leading, 4)
 }
 }
 }
 
 // Helper properties for color based on state
 private var foregroundColor: Color {
 if let validationResult = validationResult {
 switch validationResult {
 case .valid:
 return .green
 case .invalid:
 return .red
 }
 } else {
 switch state {
 case .normal:
 return .primary
 case .error:
 return .red
 case .valid:
 return .green
 }
 }
 }
 
 private var borderColor: Color {
 if let validationResult = validationResult {
 switch validationResult {
 case .valid:
 return .green
 case .invalid:
 return .red
 }
 } else {
 switch state {
 case .normal:
 return Color.gray.opacity(0.3)
 case .error:
 return .red
 case .valid:
 return .green
 }
 }
 }
 }
 
 // Updated initializer for handling ValidationResult
 extension CustomTextField {
 init(
 title: String,
 placeholder: String,
 type: TextFieldType = .regular,
 validationResult: ValidationResult? = nil,
 text: Binding<String>
 ) {
 self.title = title
 self.placeholder = placeholder
 self.type = type
 self.validationResult = validationResult
 self._text = text
 }
 }
 */
