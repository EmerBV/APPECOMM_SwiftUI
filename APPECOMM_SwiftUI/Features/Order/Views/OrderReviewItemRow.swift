//
//  OrderReviewItemRow.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct OrderReviewItemRow: View {
    let item: CartItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text("\(item.quantity)×")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let variantName = item.variantName {
                    Text("Variant: \(variantName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(item.totalPrice.toCurrentLocalePrice)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}
