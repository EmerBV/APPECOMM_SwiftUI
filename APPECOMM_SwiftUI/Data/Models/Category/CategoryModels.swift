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
    let imageFileName: String?
    let imageFileType: String?
    let imageDownloadUrl: String?
    
    var image: CategoryImage? {
        guard let imageDownloadUrl = imageDownloadUrl else { return nil }
        return CategoryImage(id: id, fileName: imageFileName ?? "", imageDownloadUrl: imageDownloadUrl)
    }
    
    init(id: Int, name: String, imageFileName: String? = nil, imageFileType: String? = nil, imageDownloadUrl: String? = nil) {
        self.id = id
        self.name = name
        self.imageFileName = imageFileName
        self.imageFileType = imageFileType
        self.imageDownloadUrl = imageDownloadUrl
    }
}

struct CategoryImage: Identifiable, Codable, Equatable {
    let id: Int
    let fileName: String
    let imageDownloadUrl: String
}
