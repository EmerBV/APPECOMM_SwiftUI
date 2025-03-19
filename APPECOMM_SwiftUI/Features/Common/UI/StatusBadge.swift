//
//  StatusBadge.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct StatusBadge: View {
    let status: ProductStatus
    
    var body: some View {
        Text(status == .inStock ? "In Stock" : "Out of Stock")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status == .inStock ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
