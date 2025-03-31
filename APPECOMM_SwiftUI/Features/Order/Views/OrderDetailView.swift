//
//  OrderDetailView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import SwiftUI

struct OrderDetailView: View {
    let orderId: Int
    @StateObject private var viewModel = OrderDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.top, 50)
                } else if let order = viewModel.order {
                    // Order header
                    orderHeaderSection(order)
                    
                    Divider()
                    
                    // Items section
                    orderItemsSection(order)
                    
                    Divider()
                    
                    // Summary section
                    orderSummarySection(order)
                    
                    // Status section
                    orderStatusSection(order)
                    
                    // Buttons
                    buttonsSection()
                    
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    Text("No order details available")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                }
            }
            .padding()
        }
        .navigationTitle("Order #\(orderId)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadOrderDetails(orderId: orderId)
        }
    }
    
    // MARK: - Section Components
    
    private func orderHeaderSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order Placed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate(order.orderDate))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(order.totalAmount.toCurrentLocalePrice)
                        .font(.headline)
                }
            }
            
            HStack {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                OrderStatusBadge(status: order.status)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
    
    private func orderItemsSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Items")
                .font(.headline)
            
            ForEach(order.items, id: \.id) { item in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Text("\(item.quantity)×")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.productName)
                            .font(.headline)
                            .lineLimit(2)
                        
                        Text(item.productBrand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let variantName = item.variantName {
                            Text("Variant: \(variantName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(item.formattedTotalPrice)
                            .font(.headline)
                        
                        if item.quantity > 1 {
                            Text("\(item.formattedPrice) each")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                if item.id != order.items.last?.id {
                    Divider()
                }
            }
        }
    }
    
    private func orderSummarySection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Summary")
                .font(.headline)
            
            Group {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(order.totalAmount.toCurrentLocalePrice)
                }
                
                // In a real app, you'd have tax and shipping details
                HStack {
                    Text("Shipping")
                    Spacer()
                    Text("Free")
                        .foregroundColor(.green)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(order.totalAmount.toCurrentLocalePrice)
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
    
    private func orderStatusSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Status")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Order Placed")
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Payment Confirmed")
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: order.status == "shipping" || order.status == "delivered" ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(order.status == "shipping" || order.status == "delivered" ? .green : .gray)
                    Text("Order Shipped")
                        .foregroundColor(order.status == "shipping" || order.status == "delivered" ? .primary : .secondary)
                }
                
                HStack {
                    Image(systemName: order.status == "delivered" ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(order.status == "delivered" ? .green : .gray)
                    Text("Order Delivered")
                        .foregroundColor(order.status == "delivered" ? .primary : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
    
    private func buttonsSection() -> some View {
        VStack(spacing: 12) {
            Button(action: {
                // In a real app, this would navigate to a support chat or email
                viewModel.contactSupport()
            }) {
                Text("Contact Support")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            
            Button(action: {
                // In a real app, this would allow reordering the same items
                viewModel.reorder()
            }) {
                Text("Reorder")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding(.top, 20)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error Loading Order")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.loadOrderDetails(orderId: orderId)
            }) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy"
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
}
