//
//  ShippingService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Combine

protocol ShippingServiceProtocol {
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetails?, NetworkError>
    func getAllShippingAddresses(userId: Int) -> AnyPublisher<[ShippingDetails], NetworkError>
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, NetworkError>
    func createShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, NetworkError>
    func deleteShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<Void, NetworkError>
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, NetworkError>
}

final class ShippingService: ShippingServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    // Obtener la dirección predeterminada de un usuario
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetails?, NetworkError> {
        let endpoint = ShippingEndpoints.getShippingDetails(userId: userId)
        Logger.info("Fetching default shipping details for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
                Logger.info("Successfully received shipping details")
                return response.data
            }
            .catch { error -> AnyPublisher<ShippingDetails?, NetworkError> in
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
    func getAllShippingAddresses(userId: Int) -> AnyPublisher<[ShippingDetails], NetworkError> {
        let endpoint = ShippingEndpoints.getAllShippingAddresses(userId: userId)
        Logger.info("Fetching all shipping addresses for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<[ShippingDetails]>.self, endpoint)
            .map { response -> [ShippingDetails] in
                Logger.info("Successfully received \(response.data.count) shipping addresses")
                return response.data
            }
            .catch { error -> AnyPublisher<[ShippingDetails], NetworkError> in
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
    
    // Actualizar una dirección existente - requiere ID en el cuerpo de la solicitud
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, NetworkError> {
        // Asegurarnos de que hay un ID para la actualización
        guard details.id != nil else {
            return Fail(error: NetworkError.badRequest(APIError(
                message: "ID is required for updating shipping details",
                code: "MISSING_ID",
                details: nil
            ))).eraseToAnyPublisher()
        }
        
        let endpoint = ShippingEndpoints.updateShippingDetails(details: details, userId: userId)
        Logger.info("Updating shipping details for user \(userId), address ID: \(details.id ?? 0)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
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
    
    // Crear una nueva dirección - no incluye ID en el cuerpo
    func createShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, NetworkError> {
        // Utilizamos el mismo endpoint que updateShippingDetails pero sin ID
        // (o con ID nulo para la API addOrUpdate)
        let endpoint = ShippingEndpoints.createShippingAddress(details: details, userId: userId)
        Logger.info("Creating new shipping address for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
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
    func deleteShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = ShippingEndpoints.deleteShippingAddress(userId: userId, addressId: addressId)
        Logger.info("Deleting shipping address \(addressId) for user \(userId)")
        
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
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, NetworkError> {
        let endpoint = ShippingEndpoints.setDefaultShippingAddress(userId: userId, addressId: addressId)
        Logger.info("Setting address \(addressId) as default for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
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
