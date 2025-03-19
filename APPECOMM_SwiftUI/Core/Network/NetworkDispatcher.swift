//
//  NetworkDispatcher.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol NetworkDispatcherProtocol {
    func dispatch<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError>
    func dispatchData(_ endpoint: APIEndpoint) -> AnyPublisher<Data, NetworkError>
    func upload<T: Decodable>(_ endpoint: APIEndpoint, data: Data) -> AnyPublisher<T, NetworkError>
}

final class NetworkDispatcher: NetworkDispatcherProtocol {
    private let sessionProvider: URLSessionProviderProtocol
    private let tokenManager: TokenManagerProtocol
    private let jsonDecoder: JSONDecoder
    
    init(sessionProvider: URLSessionProviderProtocol, tokenManager: TokenManagerProtocol) {
        self.sessionProvider = sessionProvider
        self.tokenManager = tokenManager
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
    }
    
    func dispatch<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        return executeRequest(endpoint)
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let decodingError = error as? DecodingError {
                    return .decodingError(decodingError)
                } else {
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func dispatchData(_ endpoint: APIEndpoint) -> AnyPublisher<Data, NetworkError> {
        return executeRequest(endpoint)
            .eraseToAnyPublisher()
    }
    
    func upload<T: Decodable>(_ endpoint: APIEndpoint, data: Data) -> AnyPublisher<T, NetworkError> {
        var request = sessionProvider.createURLRequest(for: endpoint)
        
        // Añadir token de autenticación si es necesario
        if endpoint.requiresAuthentication {
            if let token = tokenManager.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if !endpoint.isRefreshTokenEndpoint {
                return Fail(error: NetworkError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        return sessionProvider.uploadTaskPublisher(for: request, from: data)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                return try self.validateResponse(data: data, response: httpResponse)
            }
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let decodingError = error as? DecodingError {
                    return .decodingError(decodingError)
                } else {
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func executeRequest(_ endpoint: APIEndpoint) -> AnyPublisher<Data, NetworkError> {
        var request = sessionProvider.createURLRequest(for: endpoint)
        
        // Añadir token de autenticación si es necesario
        if endpoint.requiresAuthentication {
            if let token = tokenManager.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if !endpoint.isRefreshTokenEndpoint {
                return Fail(error: NetworkError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        return sessionProvider.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                return try self.validateResponse(data: data, response: httpResponse)
            }
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func validateResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        switch response.statusCode {
        case 200...299:
            return data
        case 401:
            // Si es un error de autorización y tenemos un refresh token, podríamos
            // implementar aquí la lógica para refrescar el token automáticamente
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400...499:
            throw NetworkError.badRequest(try? JSONDecoder().decode(APIError.self, from: data))
        case 500...599:
            throw NetworkError.serverError(try? JSONDecoder().decode(APIError.self, from: data))
        default:
            throw NetworkError.unknown(NSError(domain: "HTTPError", code: response.statusCode, userInfo: nil))
        }
    }
}
