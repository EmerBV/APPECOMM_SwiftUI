//
//  Int+Extensions.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import Foundation

extension Int {
    var toString: String {
        return String(self)
    }
}

// Helper para representar el ID como Identifiable para alertas
extension Int: @retroactive Identifiable {
    public var id: Int {
        return self
    }
}
