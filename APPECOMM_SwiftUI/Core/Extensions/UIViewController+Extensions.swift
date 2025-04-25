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
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController
        }
        
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController ?? navigationController
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController ?? tabBarController
        }
        
        return self
    }
}
