//
//  Date+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

extension Date {
    /*
     func formattedString(format: String = "dd/MM/yyyy") -> String {
     let formatter = DateFormatter()
     formatter.dateFormat = format
     return formatter.string(from: self)
     }
     */
    
    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
