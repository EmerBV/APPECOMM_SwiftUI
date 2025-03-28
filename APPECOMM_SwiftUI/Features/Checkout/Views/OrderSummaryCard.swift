//
//  OrderSummaryCard.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

// MARK: - Order Summary Card
struct OrderSummaryCard: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Order Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            HStack {
                Text("Subtotal")
                Spacer()
                Text(viewModel.orderSummary.formattedSubtotal)
            }
            
            HStack {
                Text("Tax")
                Spacer()
                Text(viewModel.orderSummary.formattedTax)
            }
            
            HStack {
                Text("Shipping")
                Spacer()
                Text(viewModel.orderSummary.formattedShipping)
            }
            
            Divider()
            
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
