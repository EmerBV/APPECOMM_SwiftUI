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
