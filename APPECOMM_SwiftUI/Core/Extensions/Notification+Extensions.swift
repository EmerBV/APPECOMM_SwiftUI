//
//  Notification+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation

extension Notification.Name {
    // Navigation notifications
    static let navigateToHomeTab = Notification.Name("NavigateToHomeTab")
    static let navigateToCartTab = Notification.Name("NavigateToCartTab")
    static let navigateToProfileTab = Notification.Name("NavigateToProfileTab")
    static let navigateToProduct = Notification.Name("NavigateToProduct")
    static let navigateToCategory = Notification.Name("NavigateToCategory")
    static let navigateToCart = Notification.Name("NavigateToCart")
    static let navigateToProfile = Notification.Name("NavigateToProfile")
    
    // Payment notifications
    static let paymentCompleted = Notification.Name("PaymentCompleted")
    static let paymentFailed = Notification.Name("PaymentFailed")
    
    // Order notifications
    static let viewOrder = Notification.Name("ViewOrder")
    static let continueShoppingAfterOrder = Notification.Name("ContinueShopping")
    
    // Cart notifications
    static let refreshCart = Notification.Name("RefreshCart")
    static let itemAddedToCart = Notification.Name("ItemAddedToCart")
    
    // User notifications
    static let userLoggedIn = Notification.Name("UserLoggedIn")
    static let userLoggedOut = Notification.Name("UserLoggedOut")
    static let userLoggedInPreloadHome = Notification.Name("UserLoggedInPreloadHome")
}
