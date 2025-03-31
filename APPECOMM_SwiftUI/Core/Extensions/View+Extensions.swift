//
//  View+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI
import Stripe
import StripePaymentSheet

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func keyboardAdaptive(isKeyboardVisible: Binding<Bool>) -> some View {
        self.modifier(KeyboardAdaptiveModifier(isKeyboardVisible: isKeyboardVisible))
    }
    
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

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct KeyboardAdaptiveModifier: ViewModifier {
    @Binding var isKeyboardVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    isKeyboardVisible = true
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    isKeyboardVisible = false
                }
            }
    }
}


