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
}
