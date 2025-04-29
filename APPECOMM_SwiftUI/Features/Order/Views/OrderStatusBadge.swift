//
//  OrderStatusBadge.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct OrderStatusBadge: View {
    let status: String
    
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
    
    private var statusText: String {
        switch status.lowercased() {
        case "pending":
            return "pending_status".localized
        case "pending_payment":
            return "pending_payment_status".localized
        case "processing":
            return "processing_status".localized
        case "paid":
            return "paid_status".localized
        case "shipped":
            return "shipped_status".localized
        case "delivered":
            return "delivered_status".localized
        case "cancelled":
            return "cancelled_status".localized
        case "refunded":
            return "refunded_status".localized
        default:
            return status.capitalized
        }
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "pending_payment":
            return .blue
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
        case "refunded":
            return .gray
        default:
            return .gray
        }
    }
}
