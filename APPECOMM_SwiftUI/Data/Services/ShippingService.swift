//
//  ShippingService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

protocol ShippingServiceProtocol {
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetailsResponse?, NetworkError>
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, NetworkError>
}

final class ShippingService: ShippingServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetailsResponse?, NetworkError> {
        let endpoint = ShippingEndpoints.getShippingDetails(userId: userId)
        Logger.info("Fetching shipping details for user \(userId)")
        
        return networkDispatcher.dispatch(ApiShippingResponse.self, endpoint)
            .map { response -> ShippingDetailsResponse in
                Logger.info("Successfully received shipping details: \(response.message)")
                return response.data
            }
            .catch { error -> AnyPublisher<ShippingDetailsResponse?, NetworkError> in
                // Si el error es 404 (no encontrado), devuelve nil (no hay detalles de envío aún)
                if case .notFound = error {
                    Logger.info("No shipping details found for user \(userId)")
                    return Just(nil)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                // Para otros errores, propaga el error
                Logger.error("Error fetching shipping details: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, NetworkError> {
        let endpoint = ShippingEndpoints.updateShippingDetails(userId: userId, details: details)
        Logger.info("Updating shipping details for user \(userId)")
        
        return networkDispatcher.dispatch(ApiShippingResponse.self, endpoint)
            .map { response -> ShippingDetailsResponse in
                Logger.info("Successfully updated shipping details: \(response.message)")
                return response.data
            }
            .eraseToAnyPublisher()
    }
}

