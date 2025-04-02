//
//  AlertItem.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation
import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissButton: Alert.Button
    let secondaryButton: Alert.Button?
    
    init(
        title: String,
        message: String,
        dismissButton: Alert.Button = .default(Text("OK")),
        secondaryButton: Alert.Button? = nil
    ) {
        self.title = title
        self.message = message
        self.dismissButton = dismissButton
        self.secondaryButton = secondaryButton
    }
    
    var alert: Alert {
        if let secondaryButton = secondaryButton {
            return Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: dismissButton,
                secondaryButton: secondaryButton
            )
        } else {
            return Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: dismissButton
            )
        }
    }
}
