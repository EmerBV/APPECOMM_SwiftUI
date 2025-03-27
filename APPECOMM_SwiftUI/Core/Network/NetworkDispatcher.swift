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
    
    // Para evitar múltiples solicitudes de renovación de token simultáneas
    private var isRefreshingToken = false
    private var refreshTokenSubject = PassthroughSubject<String, NetworkError>()
    
    init(sessionProvider: URLSessionProviderProtocol, tokenManager: TokenManagerProtocol) {
        self.sessionProvider = sessionProvider
        self.tokenManager = tokenManager
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            if let date = APPFormatters.parseDate(dateStr) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateStr)")
        }
        
        self.jsonDecoder = decoder
    }
    
    func dispatch<T: Decodable>(_ type: T.Type, _ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        Logger.debug("Dispatching request for \(String(describing: type)) to \(endpoint.path)")
        
        // Si es un endpoint de renovación de token, procesarlo directamente
        if endpoint.isRefreshTokenEndpoint {
            return executeRequestWithToken(type, endpoint)
        }
        
        // Para otros endpoints que requieren autenticación
        if endpoint.requiresAuthentication {
            return executeRequestWithAuthentication(type, endpoint)
        }
        
        // Para endpoints que no requieren autenticación
        return executeRequestWithToken(type, endpoint)
    }
    
    private func executeRequestWithAuthentication<T: Decodable>(_ type: T.Type, _ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        // Verificar si tenemos un token válido
        if tokenManager.hasValidToken() {
            // Ejecutar la solicitud con el token actual
            return executeRequestWithToken(type, endpoint)
                .catch { [weak self] (error: NetworkError) -> AnyPublisher<T, NetworkError> in
                    // Si self es nil, devolver el error original
                    guard let self = self else {
                        return Fail<T, NetworkError>(error: error).eraseToAnyPublisher()
                    }
                    
                    // Si es un error de autorización y tenemos refresh token, intentar renovar
                    if case .unauthorized = error, let refreshToken = self.tokenManager.getRefreshToken() {
                        return self.renewTokenAndExecute(type, endpoint, refreshToken)
                    }
                    
                    // Para otros errores, simplemente propagarlos
                    return Fail<T, NetworkError>(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else if let refreshToken = tokenManager.getRefreshToken() {
            // No tenemos token de acceso pero sí de renovación, intentamos renovar y ejecutar
            return renewTokenAndExecute(type, endpoint, refreshToken)
        } else {
            // No tenemos ningún token válido
            Logger.error("No hay token válido para una solicitud que requiere autenticación")
            return Fail<T, NetworkError>(error: .unauthorized).eraseToAnyPublisher()
        }
    }
    
    private func renewTokenAndExecute<T: Decodable>(_ type: T.Type, _ endpoint: APIEndpoint, _ refreshToken: String) -> AnyPublisher<T, NetworkError> {
        // Endpoint para renovar el token
        let refreshEndpoint = AuthEndpoints.refreshToken(refreshToken: refreshToken)
        
        // Primero renovar el token
        return executeRequestWithToken(ApiResponse<AuthToken>.self, refreshEndpoint)
            .map { response in
                // Guardar el nuevo token
                do {
                    try self.tokenManager.saveTokens(
                        accessToken: response.data.token,
                        refreshToken: refreshToken,
                        userId: response.data.id
                    )
                    Logger.info("Token renovado con éxito")
                } catch {
                    Logger.error("Error al guardar el token renovado: \(error)")
                }
                
                return response.data.token
            }
            .mapError { $0 as NetworkError }
            .flatMap { _ -> AnyPublisher<T, NetworkError> in
                // Ahora ejecutar la solicitud original con el nuevo token
                return self.executeRequestWithToken(type, endpoint)
            }
            .eraseToAnyPublisher()
    }
    
    private func executeRequestWithToken<T: Decodable>(_ type: T.Type, _ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        var request = sessionProvider.createURLRequest(for: endpoint)
        
        // Añadir token si es necesario
        if endpoint.requiresAuthentication {
            if let token = tokenManager.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if !endpoint.isRefreshTokenEndpoint {
                return Fail(error: NetworkError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        return sessionProvider.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response -> Data in
                guard let self = self else {
                    throw NetworkError.unknown(NSError())
                }
                
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
                    Logger.error("Decoding error: \(decodingError)")
                    return .decodingError(decodingError)
                } else {
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func dispatchData(_ endpoint: APIEndpoint) -> AnyPublisher<Data, NetworkError> {
        if endpoint.requiresAuthentication {
            // Para endpoints que requieren autenticación
            return executeDataRequestWithAuthentication(endpoint)
        }
        
        // Para endpoints que no requieren autenticación
        return executeDataRequest(endpoint)
    }
    
    private func executeDataRequestWithAuthentication(_ endpoint: APIEndpoint) -> AnyPublisher<Data, NetworkError> {
        // Verificar si tenemos un token válido
        if tokenManager.hasValidToken() {
            // Ejecutar la solicitud con el token actual
            return executeDataRequest(endpoint)
                .catch { [weak self] (error: NetworkError) -> AnyPublisher<Data, NetworkError> in
                    // Si self es nil, devolver el error original
                    guard let self = self else {
                        return Fail<Data, NetworkError>(error: error).eraseToAnyPublisher()
                    }
                    
                    // Si es un error de autorización y tenemos refresh token, intentar renovar
                    if case .unauthorized = error, let refreshToken = self.tokenManager.getRefreshToken() {
                        return self.renewTokenAndExecuteData(endpoint, refreshToken)
                    }
                    
                    // Para otros errores, simplemente propagarlos
                    return Fail<Data, NetworkError>(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else if let refreshToken = tokenManager.getRefreshToken() {
            // No tenemos token de acceso pero sí de renovación, intentamos renovar y ejecutar
            return renewTokenAndExecuteData(endpoint, refreshToken)
        } else {
            // No tenemos ningún token válido
            Logger.error("No hay token válido para una solicitud que requiere autenticación")
            return Fail<Data, NetworkError>(error: .unauthorized).eraseToAnyPublisher()
        }
    }
    
    private func renewTokenAndExecuteData(_ endpoint: APIEndpoint, _ refreshToken: String) -> AnyPublisher<Data, NetworkError> {
        // Endpoint para renovar el token
        let refreshEndpoint = AuthEndpoints.refreshToken(refreshToken: refreshToken)
        
        // Primero renovar el token
        return executeRequestWithToken(ApiResponse<AuthToken>.self, refreshEndpoint)
            .map { response in
                // Guardar el nuevo token
                do {
                    try self.tokenManager.saveTokens(
                        accessToken: response.data.token,
                        refreshToken: refreshToken,
                        userId: response.data.id
                    )
                    Logger.info("Token renovado con éxito")
                } catch {
                    Logger.error("Error al guardar el token renovado: \(error)")
                }
                
                return response.data.token
            }
            .mapError { $0 as NetworkError }
            .flatMap { _ -> AnyPublisher<Data, NetworkError> in
                // Ahora ejecutar la solicitud original con el nuevo token
                return self.executeDataRequest(endpoint)
            }
            .eraseToAnyPublisher()
    }
    
    private func executeDataRequest(_ endpoint: APIEndpoint) -> AnyPublisher<Data, NetworkError> {
        var request = sessionProvider.createURLRequest(for: endpoint)
        
        if endpoint.requiresAuthentication {
            if let token = tokenManager.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if !endpoint.isRefreshTokenEndpoint {
                return Fail(error: NetworkError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        return sessionProvider.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response -> Data in
                guard let self = self else {
                    throw NetworkError.unknown(NSError())
                }
                
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
    
    func upload<T: Decodable>(_ endpoint: APIEndpoint, data: Data) -> AnyPublisher<T, NetworkError> {
        var request = sessionProvider.createURLRequest(for: endpoint)
        
        if endpoint.requiresAuthentication {
            if let token = tokenManager.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if !endpoint.isRefreshTokenEndpoint {
                return Fail(error: NetworkError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        return sessionProvider.uploadTaskPublisher(for: request, from: data)
            .tryMap { [weak self] data, response -> Data in
                guard let self = self else {
                    throw NetworkError.unknown(NSError())
                }
                
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
    
    private func validateResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        switch response.statusCode {
        case 200...299:
            return data
        case 401:
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
