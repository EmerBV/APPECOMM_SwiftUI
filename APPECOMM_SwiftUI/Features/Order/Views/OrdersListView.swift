//
//  OrdersListView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

import SwiftUI

struct OrdersListView: View {
    @ObservedObject var viewModel: OrdersViewModel
    
    var body: some View {
        List {
            if let user = viewModel.user {
                Section(header: Text("Pedidos pendientes de pago")) {
                    if !viewModel.pendingOrders.isEmpty {
                        ForEach(viewModel.pendingOrders) { order in
                            NavigationLink(
                                destination: OrderDetailView(orderId: order.id)
                            ) {
                                OrderSummaryRow(order: order)
                            }
                        }
                    } else {
                        Text("No hay pedidos pendientes")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Historial de pedidos")) {
                    if !viewModel.completedOrders.isEmpty {
                        ForEach(viewModel.completedOrders) { order in
                            NavigationLink(
                                destination: OrderDetailView(orderId: order.id)
                            ) {
                                OrderSummaryRow(order: order)
                            }
                        }
                    } else {
                        Text("No hay pedidos en el historial")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Cargando pedidos...")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Mis Pedidos")
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
                    Text("Pedido #\(order.id)")
                        .font(.headline)
                    Spacer()
                    Text(formattedDate(from: order.orderDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total: \(order.totalAmount.toCurrentLocalePrice)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    // Badge para el estado del pedido
                    StatusState(status: order.status)
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
    
    // Componente auxiliar para mostrar el estado del pedido
    struct StatusState: View {
        let status: String
        
        var body: some View {
            Text(localizedStatus)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .foregroundColor(.white)
                .cornerRadius(4)
        }
        
        private var localizedStatus: String {
            switch status.lowercased() {
            case "pending":
                return "Pendiente"
            case "pending_payment":
                return "Pago pendiente"
            case "processing":
                return "En proceso"
            case "shipped":
                return "Enviado"
            case "delivered":
                return "Entregado"
            case "cancelled":
                return "Cancelado"
            case "refunded":
                return "Reembolsado"
            case "paid":
                return "Pagado"
            default:
                return status.capitalized
            }
        }
        
        private var statusColor: Color {
            switch status.lowercased() {
            case "pending":
                return .orange
            case "processing":
                return .blue
            case "paid":
                return .yellow
            case "shipped":
                return .purple
            case "delivered":
                return .green
            case "cancelled":
                return .red
            case "pending_payment":
                return .blue
            case "refunded":
                return .gray
            default:
                return .gray
            }
        }
    }
}
