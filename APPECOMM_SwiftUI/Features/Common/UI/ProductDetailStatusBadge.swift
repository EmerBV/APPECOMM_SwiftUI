//
//  ProductDetailStatusBadge.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 20/3/25.
//

import SwiftUI

struct ProductDetailStatusBadge: View {
    let status: ProductStatus
    
    var body: some View {
        Text(status == .inStock ? "in_stock".localized : "out_of_stock".localized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status == .inStock ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
