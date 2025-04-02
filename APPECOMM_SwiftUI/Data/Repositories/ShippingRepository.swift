//
//  ShippingRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation
import Combine

protocol ShippingRepositoryProtocol {
    var shippingDetailsState: CurrentValueSubject<ShippingDetailsState, Never> { get }
    
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetailsResponse?, Error>
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, Error>
    func saveShippingDetails(userId: Int, details: ShippingDetailsForm) -> AnyPublisher<ShippingDetailsResponse, Error>
    
    func debugShippingState()
}

final class ShippingRepository: ShippingRepositoryProtocol {
    var shippingDetailsState: CurrentValueSubject<ShippingDetailsState, Never> = CurrentValueSubject(.initial)
    
    private let shippingService: ShippingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(shippingService: ShippingServiceProtocol) {
        self.shippingService = shippingService
    }
    
    func getShippingDetails(userId: Int) -> AnyPublisher<ShippingDetailsResponse?, Error> {
        Logger.info("ShippingRepository: Getting shipping details for user: \(userId)")
        shippingDetailsState.send(.loading)
        
        return shippingService.getShippingDetails(userId: userId)
            .handleEvents(receiveOutput: { [weak self] shippingDetails in
                if let details = shippingDetails {
                    Logger.info("ShippingRepository: Received shipping details for user: \(userId)")
                    self?.shippingDetailsState.send(.loaded(details))
                } else {
                    Logger.info("ShippingRepository: No shipping details found for user: \(userId)")
                    self?.shippingDetailsState.send(.empty)
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to get shipping details: \(error)")
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateShippingDetails(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetailsResponse, Error> {
        Logger.info("ShippingRepository: Updating shipping details for user: \(userId)")
        shippingDetailsState.send(.loading)
        
        return shippingService.updateShippingDetails(userId: userId, details: details)
            .handleEvents(receiveOutput: { [weak self] shippingDetails in
                Logger.info("ShippingRepository: Shipping details updated successfully")
                self?.shippingDetailsState.send(.loaded(shippingDetails))
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to update shipping details: \(error)")
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func saveShippingDetails(userId: Int, details: ShippingDetailsForm) -> AnyPublisher<ShippingDetailsResponse, Error> {
        // Validar los datos del formulario antes de enviarlos
        var formCopy = details
        formCopy.validateAll()
        
        guard formCopy.isValid else {
            let errorMessage = "Formulario inválido. Por favor, verifica los campos."
            shippingDetailsState.send(.error(errorMessage))
            return Fail(error: NSError(domain: "ShippingRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                .eraseToAnyPublisher()
        }
        
        // Convertir el formulario a un request para la API
        let request = formCopy.toRequest()
        
        return updateShippingDetails(userId: userId, details: request)
    }
    
    func debugShippingState() {
        Logger.debug("Current shipping details state: \(shippingDetailsState.value)")
        
        if case .loaded(let details) = shippingDetailsState.value {
            Logger.debug("Shipping details loaded - ID: \(details.id), Name: \(details.fullName ?? "N/A"), Address: \(details.address)")
        }
    }
}
