//
//  PrimaryButton.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

/*
 struct PrimaryButton: View {
 let title: String
 let isLoading: Bool
 let isEnabled: Bool
 let action: () -> Void
 
 var body: some View {
 Button(action: action) {
 HStack {
 if isLoading {
 ProgressView()
 .progressViewStyle(CircularProgressViewStyle(tint: .white))
 .padding(.trailing, 8)
 }
 
 Text(title)
 .font(.headline)
 .fontWeight(.semibold)
 }
 .frame(maxWidth: .infinity)
 .padding()
 .background(isEnabled ? Color.blue : Color.gray)
 .foregroundColor(.white)
 .cornerRadius(10)
 }
 .disabled(!isEnabled || isLoading)
 }
 }
 */

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                action()
            }
        }) {
            ZStack {
                // Button background
                Rectangle()
                    .fill(isEnabled ? Color.blue : Color.gray.opacity(0.5))
                    .cornerRadius(10)
                
                // Button content - either text or loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 50)
        }
        .disabled(!isEnabled || isLoading)
    }
}
