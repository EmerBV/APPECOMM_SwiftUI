//
//  ApiResponse.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

struct ApiResponse<T: Codable>: Codable {
    let message: String
    let data: T
}
