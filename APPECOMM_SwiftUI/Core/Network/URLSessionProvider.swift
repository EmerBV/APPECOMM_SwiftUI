//
//  URLSessionProvider.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol URLSessionProviderProtocol {
    func createURLRequest(for endpoint: APIEndpoint) -> URLRequest
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error>
    func uploadTaskPublisher(for request: URLRequest, from data: Data) -> AnyPublisher<(data: Data, response: URLResponse), Error>
}

final class URLSessionProvider: URLSessionProviderProtocol {
    private let configuration: APIConfigurationProtocol
    private let session: URLSession
    private let logger: NetworkLoggerProtocol
    
    init(configuration: APIConfigurationProtocol, logger: NetworkLoggerProtocol) {
        self.configuration = configuration
        self.logger = logger
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfiguration.timeoutIntervalForResource = configuration.timeoutInterval
        
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    func createURLRequest(for endpoint: APIEndpoint) -> URLRequest {
        let url = configuration.baseURL.appendingPathComponent(endpoint.path)
        
        // Initialize URL components for handling query parameters
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Handle query parameters if present
        if let queryParams = endpoint.queryParameters, !queryParams.isEmpty {
            components?.queryItems = queryParams.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        // Use the URL with added query parameters if available, otherwise use the original URL
        let requestURL = components?.url ?? url
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = endpoint.method
        
        // Añadir headers por defecto
        configuration.defaultHeaders.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Añadir headers específicos del endpoint
        endpoint.headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Configurar body
        if let parameters = endpoint.parameters {
            switch endpoint.encoding {
            case .json:
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    // Ensure we have the correct content-type header for JSON
                    if request.value(forHTTPHeaderField: "Content-Type") == nil {
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                } catch {
                    logger.logRequest(request)
                    assertionFailure("Error al serializar parámetros: \(error.localizedDescription)")
                }
            case .url:
                if var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
                    let existingItems = components.queryItems ?? []
                    let newItems = parameters.map { key, value in
                        URLQueryItem(name: key, value: "\(value)")
                    }
                    components.queryItems = existingItems + newItems
                    request.url = components.url
                }
            }
        }
        
        // Registrar para debugging
        logger.logRequest(request)
        
        return request
    }
    
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        return session.dataTaskPublisher(for: request)
            .handleEvents(receiveOutput: { [weak self] data, response in
                self?.logger.logResponse(response, data: data, error: nil)
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.logResponse(nil, data: nil, error: error)
                }
            })
            .mapError { error -> Error in
                // Convertir URLError a Error
                return error as Error
            }
            .eraseToAnyPublisher()
    }
    
    func uploadTaskPublisher(for request: URLRequest, from data: Data) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        return session.uploadTaskPublisher(for: request, from: data)
            .handleEvents(receiveOutput: { [weak self] data, response in
                self?.logger.logResponse(response, data: data, error: nil)
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.logResponse(nil, data: nil, error: error)
                }
            })
            .mapError { error -> Error in
                // Convertir URLError a Error
                return error as Error
            }
            .eraseToAnyPublisher()
    }
}

// Helper para añadir método uploadTaskPublisher a URLSession
extension URLSession {
    func uploadTaskPublisher(for request: URLRequest, from bodyData: Data) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        return Deferred {
            Future<(data: Data, response: URLResponse), Error> { promise in
                let task = self.uploadTask(with: request, from: bodyData) { data, response, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let response = response else {
                        promise(.failure(NetworkError.invalidResponse))
                        return
                    }
                    
                    guard let data = data else {
                        promise(.failure(NetworkError.noData))
                        return
                    }
                    
                    promise(.success((data: data, response: response)))
                }
                task.resume()
            }
        }.eraseToAnyPublisher()
    }
}
