//
//  OrderSummaryCheckout.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation

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
