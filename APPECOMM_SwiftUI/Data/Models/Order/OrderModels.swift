//
//  OrderModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

// MARK: - Order Model
struct Order: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let orderDate: String
    let totalAmount: Decimal
    let status: String
    let items: [OrderItem]
    let shippingDetailsId: Int?
    let paymentMethod: String?
    let paymentIntentId: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "orderId"
        case userId
        case orderDate
        case totalAmount
        case status = "orderStatus"
        case items = "orderItems"
        case shippingDetailsId = "shipping_details_id"
        case paymentMethod
        case paymentIntentId
    }
    
    static func == (lhs: Order, rhs: Order) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Order Item Model
struct OrderItem: Identifiable, Codable, Equatable {
    let id: Int?
    let productId: Int
    let productName: String
    let productBrand: String
    let variantId: Int?
    let variantName: String?
    let quantity: Int
    let price: Decimal
    let totalPrice: Decimal
    
    var formattedPrice: String {
        return price.toCurrentLocalePrice
    }
    
    var formattedTotalPrice: String {
        return totalPrice.toCurrentLocalePrice
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId
        case productName
        case productBrand
        case variantId
        case variantName
        case quantity
        case price
        case totalPrice
    }
    
    static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        // Use IDs for comparison if available, otherwise full object comparison
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId == rhsId
        }
        return lhs.productId == rhs.productId &&
        lhs.variantId == rhs.variantId &&
        lhs.quantity == rhs.quantity
    }
}

struct OrderSummaryCheckout {
    var subtotal: Decimal = 0
    var tax: Decimal = 0
    var shippingCost: Decimal = 0
    
    var total: Decimal {
        return subtotal + tax + shippingCost
    }
    
    var formattedSubtotal: String {
        return subtotal.toCurrentLocalePrice
    }
    
    var formattedTax: String {
        return tax.toCurrentLocalePrice
    }
    
    var formattedShipping: String {
        return shippingCost > 0 ? shippingCost.toCurrentLocalePrice : "shipping_calculated".localized
    }
    
    var formattedTotal: String {
        return total.toCurrentLocalePrice
    }
}

enum OrderStatus: String, Codable, Equatable, CaseIterable {
    case pending = "PENDING"
    case processing = "PROCESSING"
    case paid = "PAID"
    case shipped = "SHIPPED"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
    case refunded = "REFUNDED"
    
    var displayName: String {
        switch self {
        case .pending:
            return NSLocalizedString("order_status_pending", comment: "Order status: pending")
        case .processing:
            return NSLocalizedString("order_status_processing", comment: "Order status: processing")
        case .paid:
            return NSLocalizedString("order_status_paid", comment: "Order status: paid")
        case .shipped:
            return NSLocalizedString("order_status_shipped", comment: "Order status: shipped")
        case .delivered:
            return NSLocalizedString("order_status_delivered", comment: "Order status: delivered")
        case .cancelled:
            return NSLocalizedString("order_status_cancelled", comment: "Order status: cancelled")
        case .refunded:
            return NSLocalizedString("order_status_refunded", comment: "Order status: refunded")
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "StatusYellow"
        case .processing:
            return "StatusBlue"
        case .paid:
            return "StatusPink"
        case .shipped:
            return "StatusPurple"
        case .delivered:
            return "StatusGreen"
        case .cancelled:
            return "StatusRed"
        case .refunded:
            return "StatusOrange"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending:
            return "hourglass"
        case .processing:
            return "gearshape.2"
        case .paid:
            return "cash"
        case .shipped:
            return "shippingbox"
        case .delivered:
            return "checkmark.circle"
        case .cancelled:
            return "xmark.circle"
        case .refunded:
            return "arrow.triangle.2.circlepath"
        }
    }
}
