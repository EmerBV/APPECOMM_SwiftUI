//
//  OrdersListView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

import SwiftUI

struct OrdersListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: OrdersViewModel
    
    var body: some View {
        List {
            if let user = viewModel.user {
                Section(header: Text("pending_payment".localized)) {
                    if !viewModel.pendingOrders.isEmpty {
                        ForEach(viewModel.pendingOrders) { order in
                            NavigationLink(
                                destination: OrderDetailView(orderId: order.id)
                            ) {
                                OrderSummaryRow(order: order)
                            }
                        }
                    } else {
                        Text("no_pending_orders".localized)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("order_history".localized)) {
                    if !viewModel.completedOrders.isEmpty {
                        ForEach(viewModel.completedOrders) { order in
                            NavigationLink(
                                destination: OrderDetailView(orderId: order.id)
                            ) {
                                OrderSummaryRow(order: order)
                            }
                        }
                    } else {
                        Text("no_orders_history".localized)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("loading_orders".localized)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("my_orders".localized)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    //.foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            viewModel.loadOrders()
        }
        .refreshable {
            viewModel.loadOrders()
        }
    }
    
    struct OrderSummaryRow: View {
        let order: Order
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "order".localized, order.id))
                        .font(.headline)
                    Spacer()
                    Text(formattedDate(from: order.orderDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("total_label".localized + ":" + " \(order.totalAmount.toCurrentLocalePrice)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    // Badge para el estado del pedido
                    OrderStatusBadge(status: order.status)
                }
            }
            .padding(.vertical, 8)
        }
        
        private func formattedDate(from dateString: String) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            
            if let date = dateFormatter.date(from: dateString) {
                dateFormatter.dateFormat = "dd/MM/yyyy"
                return dateFormatter.string(from: date)
            }
            
            return dateString
        }
    }
}
