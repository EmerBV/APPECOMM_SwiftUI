//
//  PaymentSheetWrapper.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import Stripe

// Wrapper para poder usar PaymentSheet con la API de Stripe
typealias PaymentSheet = STPPaymentSheet
typealias PaymentSheetResult = STPPaymentSheetResult
typealias PaymentSheetConfiguration = STPPaymentSheet.Configuration
typealias PaymentSheetAppearance = STPPaymentSheet.Appearance
typealias PaymentSheetError = STPPaymentSheetError
