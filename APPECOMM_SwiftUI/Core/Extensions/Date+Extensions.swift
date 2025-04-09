//
//  Date+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

extension Date {
    var toFormattedDate: String {
        return APPFormatters.formattedDate(self)
    }
}
