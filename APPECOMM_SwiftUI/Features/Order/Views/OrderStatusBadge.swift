//
//  OrderStatusBadge.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct OrderStatusBadge: View {
    let status: String
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "paid":
            return .yellow
        case "processing":
            return .blue
        case "shipping":
            return .purple
        case "delivered":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch status.lowercased() {
        case "pending":
            return "Pending"
        case "paid":
            return "Paid"
        case "processing":
            return "Processing"
        case "shipping":
            return "Shipping"
        case "delivered":
            return "Delivered"
        case "cancelled":
            return "Cancelled"
        default:
            return status.capitalized
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}

