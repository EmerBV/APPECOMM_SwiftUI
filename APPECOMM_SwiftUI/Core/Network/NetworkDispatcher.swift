//
//  NetworkDispatcher.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol NetworkDispatcherProtocol {
    func dispatch<T: Decodable>(_ type: T.Type, _ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError>
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // Intentar con diferentes formatos de fecha
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd"
            ]
            
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateStr) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateStr)")
        }
        
        self.jsonDecoder = decoder
    }
    
    func dispatch<T: Decodable>(_ type: T.Type, _ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        
        print("NetworkDispatcher: Dispatching request for \(String(describing: type)) to \(endpoint.path)")
        
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
            .decode(type: type, decoder: jsonDecoder)
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let decodingError = error as? DecodingError {
                    print("NetworkDispatcher: Decoding error - \(decodingError)")
                    
                    // Añadir info detallada del error para depuración
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("NetworkDispatcher: Type mismatch for \(type) at path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("NetworkDispatcher: Value not found for \(type) at path: \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("NetworkDispatcher: Key '\(key.stringValue)' not found at path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("NetworkDispatcher: Data corrupted at path: \(context.codingPath), description: \(context.debugDescription)")
                    @unknown default:
                        print("NetworkDispatcher: Unknown decoding error")
                    }
                    
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
