//
//  StripeCustomer.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation

struct StripeCustomer: Codable {
    let id: String
    let email: String
    let name: String?
    let created: Int
    let defaultSource: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case created
        case defaultSource = "default_source"
    }
}
