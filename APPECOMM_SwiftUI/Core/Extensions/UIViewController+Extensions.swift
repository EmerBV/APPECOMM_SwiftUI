//
//  UIViewController+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import UIKit
import Stripe

// Extensión para hacer que UIViewController conforme a STPAuthenticationContext
extension UIViewController: @retroactive STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        return self
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController ?? self
        }
        return self
    }
}
