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
            Text("Order Summary")
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
                    Text("And \(cart.items.count - 3) more items...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
            }
            
            // Subtotal
            HStack {
                Text("Subtotal")
                Spacer()
                Text(viewModel.orderSummary.formattedSubtotal)
            }
            
            // Tax
            HStack {
                Text("Tax")
                Spacer()
                Text(viewModel.orderSummary.formattedTax)
            }
            
            // Shipping
            HStack {
                Text("Shipping")
                Spacer()
                Text(viewModel.orderSummary.formattedShipping)
            }
            
            Divider()
            
            // Total
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(viewModel.orderSummary.formattedTotal)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
