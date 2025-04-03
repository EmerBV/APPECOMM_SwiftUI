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
    func getAllShippingAddresses(userId: Int) -> AnyPublisher<[ShippingDetailsResponse], NetworkError>
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, NetworkError>
    func createShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, NetworkError>
    func deleteShippingAddress(addressId: Int) -> AnyPublisher<Void, NetworkError>
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetailsResponse, NetworkError>
}

final class ShippingService: ShippingServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    // Obtener una dirección específica (compatibilidad con código existente)
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetailsResponse?, NetworkError> {
        let endpoint = ShippingEndpoints.getShippingDetails(userId: userId)
        Logger.info("Fetching default shipping details for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetailsResponse>.self, endpoint)
            .map { response -> ShippingDetailsResponse in
                Logger.info("Successfully received shipping details")
                return response.data
            }
            .catch { error -> AnyPublisher<ShippingDetailsResponse?, NetworkError> in
                // If 404 (not found), return nil (no shipping details yet)
                if case .notFound = error {
                    Logger.info("No shipping details found for user \(userId)")
                    return Just(nil)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                // For other errors, propagate the error
                Logger.error("Error fetching shipping details: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Obtener todas las direcciones de un usuario
    func getAllShippingAddresses(userId: Int) -> AnyPublisher<[ShippingDetailsResponse], NetworkError> {
        let endpoint = ShippingEndpoints.getAllShippingAddresses(userId: userId)
        Logger.info("Fetching all shipping addresses for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<[ShippingDetailsResponse]>.self, endpoint)
            .map { response -> [ShippingDetailsResponse] in
                Logger.info("Successfully received \(response.data.count) shipping addresses")
                return response.data
            }
            .catch { error -> AnyPublisher<[ShippingDetailsResponse], NetworkError> in
                // If 404 (not found), return empty array
                if case .notFound = error {
                    Logger.info("No shipping addresses found for user \(userId)")
                    return Just([])
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                // For other errors, propagate the error
                Logger.error("Error fetching shipping addresses: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Actualizar una dirección existente
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, NetworkError> {
        let endpoint = ShippingEndpoints.updateShippingDetails(details: details, userId: userId)
        Logger.info("Updating shipping details for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetailsResponse>.self, endpoint)
            .map { response -> ShippingDetailsResponse in
                Logger.info("Successfully updated shipping details")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to update shipping details: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Crear una nueva dirección
    func createShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, NetworkError> {
        let endpoint = ShippingEndpoints.createShippingAddress(details: details, userId: userId)
        Logger.info("Creating new shipping address for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetailsResponse>.self, endpoint)
            .map { response -> ShippingDetailsResponse in
                Logger.info("Successfully created shipping address")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to create shipping address: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Eliminar una dirección
    func deleteShippingAddress(addressId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = ShippingEndpoints.deleteShippingAddress(addressId: addressId)
        Logger.info("Deleting shipping address \(addressId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("Successfully deleted shipping address")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to delete shipping address: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Establecer una dirección como predeterminada
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetailsResponse, NetworkError> {
        let endpoint = ShippingEndpoints.setDefaultShippingAddress(userId: userId, addressId: addressId)
        Logger.info("Setting address \(addressId) as default for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetailsResponse>.self, endpoint)
            .map { response -> ShippingDetailsResponse in
                Logger.info("Successfully set default shipping address")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to set default shipping address: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
