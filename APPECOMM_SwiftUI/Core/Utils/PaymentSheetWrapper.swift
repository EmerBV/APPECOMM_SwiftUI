//
//  PaymentSheetWrapper.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import Stripe
import SwiftUI

// Wrappers para los tipos de Stripe para simplificar su uso
typealias PaymentSheet = STPPaymentSheet
typealias PaymentSheetResult = STPPaymentSheetResult
typealias PaymentSheetConfiguration = STPPaymentSheet.Configuration
typealias PaymentSheetAppearance = STPPaymentSheet.Appearance
typealias PaymentSheetError = STPPaymentSheetError

// Extensión para View para integrar fácilmente PaymentSheet en SwiftUI
extension View {
    func paymentSheet(
        isPresented: Binding<Bool>,
        paymentSheet: PaymentSheet?,
        onCompletion: @escaping (PaymentSheetResult) -> Void
    ) -> some View {
        self.modifier(PaymentSheetViewModifier(
            isPresented: isPresented,
            paymentSheet: paymentSheet,
            onCompletion: onCompletion
        ))
    }
}

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

