//
//  APIEndpoint.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum ParameterEncoding {
    case json
    case url
}

protocol APIEndpoint {
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var queryParameters: [String: Any]? { get }
    var encoding: ParameterEncoding { get }
    var requiresAuthentication: Bool { get }
    var isRefreshTokenEndpoint: Bool { get }
}

extension APIEndpoint {
    var headers: [String: String]? { return nil }
    var parameters: [String: Any]? { return nil }
    var queryParameters: [String: Any]? { return nil }
    var encoding: ParameterEncoding { return .json }
    var requiresAuthentication: Bool { return false }
    var isRefreshTokenEndpoint: Bool { return false }
}
