//
//  StatusBadge.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

enum StatusBadge: View {
    case outOfStock
    case preOrder
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var text: String {
        switch self {
        case .outOfStock:
            return "Sin Stock"
        case .preOrder:
            return "Pre-order"
        }
    }
    
    private var color: Color {
        switch self {
        case .outOfStock:
            return .red
        case .preOrder:
            return .blue
        }
    }
}
