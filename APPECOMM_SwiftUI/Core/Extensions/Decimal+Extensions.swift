//
//  Decimal+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 27/3/25.
//

import Foundation

extension Decimal {
    var toCurrentLocalePrice: String {
        return APPFormatters.formattedPrice(self)
    }
    
    func rounded(_ scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, mode)
        return result
    }
}
