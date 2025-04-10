//
//  CategoryModels.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 10/4/25.
//

import Foundation

struct Category: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let image: CategoryImage?
}

struct CategoryImage: Identifiable, Codable, Equatable {
    let id: Int
    let fileName: String
    let imageDownloadUrl: String
}
