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
    func getShippingDetailsById(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, NetworkError>
}

final class ShippingService: ShippingServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    // Obtener la dirección predeterminada de un usuario
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetails?, NetworkError> {
        let endpoint = ShippingEndpoints.getShippingDetails(userId: userId)
        Logger.info("ShippingService: Fetching default shipping details for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
                Logger.info("ShippingService: Successfully received shipping details")
                return response.data
            }
            .catch { error -> AnyPublisher<ShippingDetails?, NetworkError> in
                // If 404 (not found), return nil (no shipping details yet)
                if case .notFound = error {
                    Logger.info("ShippingService: No shipping details found for user \(userId)")
                    return Just(nil)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                // For other errors, propagate the error
                Logger.error("ShippingService: Error fetching shipping details: \(error)")
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
                    Logger.info("ShippingService: No shipping addresses found for user \(userId)")
                    return Just([])
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                // For other errors, propagate the error
                Logger.error("ShippingService: Error fetching shipping addresses: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Actualizar una dirección existente - requiere ID en el cuerpo de la solicitud
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, NetworkError> {
        // Determinar si estamos creando o actualizando basado en si hay un ID
        let isUpdate = details.id != nil
        
        // Log para depuración
        if isUpdate {
            Logger.info("ShippingService: Updating shipping details for user \(userId), address ID: \(details.id!)")
        } else {
            Logger.info("ShippingService: Creating new shipping details for user \(userId)")
        }
        
        // Elegir el endpoint adecuado según si estamos creando o actualizando
        let endpoint = isUpdate
        ? ShippingEndpoints.updateShippingDetails(details: details, userId: userId)
        : ShippingEndpoints.createShippingAddress(details: details, userId: userId)
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
                if isUpdate {
                    Logger.info("ShippingService: Successfully updated shipping details")
                } else {
                    Logger.info("ShippingService: Successfully created shipping details")
                }
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingService: Failed to \(isUpdate ? "update" : "create") shipping details: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Método alternativo para crear una dirección sin preocuparse por el ID
    func createShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, NetworkError> {
        // Asegurar que no se proporciona un ID para la creación
        var requestCopy = details
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        if let data = try? encoder.encode(details),
           var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Eliminar el ID explícitamente para asegurarnos de que estamos creando
            dict.removeValue(forKey: "id")
            
            if let cleanData = try? JSONSerialization.data(withJSONObject: dict),
               let cleanRequest = try? decoder.decode(ShippingDetailsRequest.self, from: cleanData) {
                requestCopy = cleanRequest
            }
        }
        
        let endpoint = ShippingEndpoints.createShippingAddress(details: requestCopy, userId: userId)
        Logger.info("ShippingService: Creating new shipping address for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
                Logger.info("ShippingService: Successfully created shipping address")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingService: Failed to create shipping address: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Eliminar una dirección
    func deleteShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<Void, NetworkError> {
        let endpoint = ShippingEndpoints.deleteShippingAddress(userId: userId, addressId: addressId)
        Logger.info("ShippingService: Deleting shipping address \(addressId) for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<EmptyResponse>.self, endpoint)
            .map { _ -> Void in
                Logger.info("ShippingService: Successfully deleted shipping address")
                return ()
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingService: Failed to delete shipping address: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Establecer una dirección como predeterminada
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, NetworkError> {
        let endpoint = ShippingEndpoints.setDefaultShippingAddress(userId: userId, addressId: addressId)
        Logger.info("ShippingService: Setting address \(addressId) as default for user \(userId)")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
                Logger.info("ShippingService: Successfully set default shipping address")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingService: Failed to set default shipping address: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getShippingDetailsById(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, NetworkError> {
        let endpoint = ShippingEndpoints.getShippingDetailsById(userId: userId, addressId: addressId)
        Logger.info("ShippingService: Fetching shipping details for address \(addressId) (user \(userId))")
        
        return networkDispatcher.dispatch(ApiResponse<ShippingDetails>.self, endpoint)
            .map { response -> ShippingDetails in
                Logger.info("ShippingService: Successfully received shipping details")
                return response.data
            }
            .catch { error -> AnyPublisher<ShippingDetails, NetworkError> in
                // For errors, propagate the error
                Logger.error("ShippingService: Error fetching shipping details: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
