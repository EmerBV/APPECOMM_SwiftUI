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
}

struct CustomTextField: View {
    enum TextFieldType {
        case regular, secure
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
        }
    }
}
