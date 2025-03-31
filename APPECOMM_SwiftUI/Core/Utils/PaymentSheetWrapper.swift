//
//  PaymentSheetWrapper.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import Stripe
import StripePaymentSheet
import SwiftUI

// Wrappers para los tipos de Stripe para simplificar su uso
typealias PaymentSheet = StripePaymentSheet.PaymentSheet
typealias PaymentSheetResult = StripePaymentSheet.PaymentSheetResult
typealias PaymentSheetConfiguration = StripePaymentSheet.PaymentSheet.Configuration
typealias PaymentSheetAppearance = StripePaymentSheet.PaymentSheet.Appearance
typealias PaymentSheetError = StripePaymentSheet.PaymentSheetError

// Modificador personalizado para manejar el paymentSheet opcional
struct PaymentSheetViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    var paymentSheet: PaymentSheet?
    var onCompletion: (PaymentSheetResult) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { presented in
                if presented, let sheet = paymentSheet {
                    let windowScene = UIApplication.shared.connectedScenes
                        .first as? UIWindowScene
                    
                    if let rootViewController = windowScene?.windows.first?.rootViewController {
                        sheet.present(from: rootViewController) { result in
                            isPresented = false
                            onCompletion(result)
                        }
                    }
                }
            }
    }
}

