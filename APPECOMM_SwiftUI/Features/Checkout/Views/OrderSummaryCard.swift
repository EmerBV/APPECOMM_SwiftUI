//
//  OrderSummaryCard.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct OrderSummaryCard: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("order_summary".localized)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Items summary (optional, can be expanded)
            if let cart = viewModel.cart, !cart.items.isEmpty {
                ForEach(cart.items.prefix(3)) { item in
                    HStack {
                        Text("\(item.quantity)× \(item.product.name)")
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(item.totalPrice.toCurrentLocalePrice)
                            .font(.subheadline)
                    }
                }
                
                if cart.items.count > 3 {
                    Text(String(format: "and_more_items".localized, cart.items.count - 3))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
            }
            
            // Subtotal
            HStack {
                Text("subtotal".localized)
                Spacer()
                Text(viewModel.orderSummary.subtotal.toCurrentLocalePrice)
            }
            
            // Tax
            HStack {
                Text("tax_label".localized)
                Spacer()
                Text(viewModel.orderSummary.tax.toCurrentLocalePrice)
            }
            
            // Shipping
            HStack {
                Text("shipping".localized)
                Spacer()
                Text(viewModel.orderSummary.formattedShipping)
            }
            
            Divider()
            
            // Total
            HStack {
                Text("total".localized)
                    .fontWeight(.semibold)
                Spacer()
                Text(viewModel.orderSummary.total.toCurrentLocalePrice)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
