//
//  ErrorToast.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct ErrorToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .zIndex(100)
    }
}
