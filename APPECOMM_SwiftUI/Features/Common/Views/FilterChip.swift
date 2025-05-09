//
//  FilterChip.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/5/25.
//

import SwiftUI

struct FilterChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

