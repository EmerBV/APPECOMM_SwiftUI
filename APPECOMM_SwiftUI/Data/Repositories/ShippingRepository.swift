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
    var shippingAddressesState: CurrentValueSubject<ShippingAddressesState, Never> { get }
    
    func getDefaultShippingAddress(userId: Int) -> AnyPublisher<ShippingDetails?, Error>
    func getAllShippingAddresses(userId: Int) -> AnyPublisher<[ShippingDetails], Error>
    func updateShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, Error>
    func createShippingAddress(userId: Int, details: ShippingDetailsForm) -> AnyPublisher<ShippingDetails, Error>
    func deleteShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<Void, Error>
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, Error>
    
    func debugShippingState()
}

final class ShippingRepository: ShippingRepositoryProtocol {
    var shippingDetailsState: CurrentValueSubject<ShippingDetailsState, Never> = CurrentValueSubject(.initial)
    var shippingAddressesState: CurrentValueSubject<ShippingAddressesState, Never> = CurrentValueSubject(.initial)
    
    private let shippingService: ShippingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(shippingService: ShippingServiceProtocol) {
        self.shippingService = shippingService
    }
    
    func getDefaultShippingAddress(userId: Int) -> AnyPublisher<ShippingDetails?, Error> {
        Logger.info("ShippingRepository: Getting default shipping address for user: \(userId)")
        shippingDetailsState.send(.loading)
        
        return shippingService.getShippingDetails(userId: userId)
            .handleEvents(receiveOutput: { [weak self] shippingDetails in
                if let details = shippingDetails {
                    Logger.info("ShippingRepository: Received default shipping address for user: \(userId)")
                    self?.shippingDetailsState.send(.loaded(details))
                } else {
                    Logger.info("ShippingRepository: No default shipping address found for user: \(userId)")
                    self?.shippingDetailsState.send(.empty)
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to get default shipping address: \(error)")
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getAllShippingAddresses(userId: Int) -> AnyPublisher<[ShippingDetails], Error> {
        Logger.info("ShippingRepository: Getting all shipping addresses for user: \(userId)")
        shippingAddressesState.send(.loading)
        
        return shippingService.getAllShippingAddresses(userId: userId)
            .handleEvents(receiveOutput: { [weak self] addresses in
                if addresses.isEmpty {
                    Logger.info("ShippingRepository: No shipping addresses found for user: \(userId)")
                    self?.shippingAddressesState.send(.empty)
                } else {
                    Logger.info("ShippingRepository: Received \(addresses.count) shipping addresses for user: \(userId)")
                    self?.shippingAddressesState.send(.loaded(addresses))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to get shipping addresses: \(error)")
                    self?.shippingAddressesState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateShippingAddress(userId: Int, details: ShippingDetailsRequest) -> AnyPublisher<ShippingDetails, Error> {
        Logger.info("ShippingRepository: Updating shipping address ID: \(details.id ?? 0) for user: \(userId)")
        shippingDetailsState.send(.loading)
        
        // Asegurarnos de que tenemos un ID para actualizar
        guard details.id != nil else {
            let error = NSError(domain: "ShippingRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "ID required for update"])
            shippingDetailsState.send(.error(error.localizedDescription))
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return shippingService.updateShippingDetails(userId: userId, details: details)
            .handleEvents(receiveOutput: { [weak self] shippingDetails in
                Logger.info("ShippingRepository: Shipping address updated successfully")
                self?.shippingDetailsState.send(.loaded(shippingDetails))
                
                // Refresh the addresses list if it's loaded
                if case .loaded = self?.shippingAddressesState.value {
                    self?.getAllShippingAddresses(userId: userId)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &self!.cancellables)
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to update shipping address: \(error)")
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func createShippingAddress(userId: Int, details: ShippingDetailsForm) -> AnyPublisher<ShippingDetails, Error> {
        // Validate form data first
        var formCopy = details
        formCopy.validateAll()
        
        guard formCopy.isValid else {
            let errorMessage = "Invalid form data. Please check all fields."
            shippingDetailsState.send(.error(errorMessage))
            return Fail(error: NSError(domain: "ShippingRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                .eraseToAnyPublisher()
        }
        
        // Convert form to API request - para crear, ID debe ser nil
        let request = formCopy.toRequest(id: nil)
        
        Logger.info("ShippingRepository: Creating new shipping address for user: \(userId)")
        shippingDetailsState.send(.loading)
        
        return shippingService.createShippingAddress(userId: userId, details: request)
            .handleEvents(receiveOutput: { [weak self] shippingDetails in
                Logger.info("ShippingRepository: Shipping address created successfully")
                self?.shippingDetailsState.send(.loaded(shippingDetails))
                
                // Refresh the addresses list
                self?.getAllShippingAddresses(userId: userId)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self!.cancellables)
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to create shipping address: \(error)")
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func deleteShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<Void, Error> {
        Logger.info("ShippingRepository: Deleting shipping address: \(addressId) for user: \(userId)")
        
        return shippingService.deleteShippingAddress(userId: userId, addressId: addressId)
            .handleEvents(receiveOutput: { [weak self] _ in
                Logger.info("ShippingRepository: Shipping address deleted successfully")
                
                // Update the addresses list state if loaded
                if case .loaded(let addresses) = self?.shippingAddressesState.value {
                    let updatedAddresses = addresses.filter { $0.id != addressId }
                    if updatedAddresses.isEmpty {
                        self?.shippingAddressesState.send(.empty)
                    } else {
                        self?.shippingAddressesState.send(.loaded(updatedAddresses))
                    }
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to delete shipping address: \(error)")
                    // Send error to both states for UI handling
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                    self?.shippingAddressesState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func setDefaultShippingAddress(userId: Int, addressId: Int) -> AnyPublisher<ShippingDetails, Error> {
        Logger.info("ShippingRepository: Setting address \(addressId) as default for user: \(userId)")
        
        return shippingService.setDefaultShippingAddress(userId: userId, addressId: addressId)
            .handleEvents(receiveOutput: { [weak self] defaultAddress in
                Logger.info("ShippingRepository: Default shipping address set successfully")
                self?.shippingDetailsState.send(.loaded(defaultAddress))
                
                // Update the addresses list with the new default
                if case .loaded(var addresses) = self?.shippingAddressesState.value {
                    // Update isDefault flag for all addresses
                    addresses = addresses.map { address in
                        var updatedAddress = address
                        if address.id == addressId {
                            // This one is now the default
                            updatedAddress = ShippingDetails(
                                id: address.id,
                                address: address.address,
                                city: address.city,
                                state: address.state,
                                postalCode: address.postalCode,
                                country: address.country,
                                phoneNumber: address.phoneNumber,
                                fullName: address.fullName,
                                isDefault: true
                            )
                        } else if address.isDefault == true {
                            // Others are no longer default
                            updatedAddress = ShippingDetails(
                                id: address.id,
                                address: address.address,
                                city: address.city,
                                state: address.state,
                                postalCode: address.postalCode,
                                country: address.country,
                                phoneNumber: address.phoneNumber,
                                fullName: address.fullName,
                                isDefault: false
                            )
                        }
                        return updatedAddress
                    }
                    
                    self?.shippingAddressesState.send(.loaded(addresses))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ShippingRepository: Failed to set default shipping address: \(error)")
                    self?.shippingDetailsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func debugShippingState() {
        Logger.debug("Current shipping details state: \(shippingDetailsState.value)")
        Logger.debug("Current shipping addresses state: \(shippingAddressesState.value)")
        
        if case .loaded(let details) = shippingDetailsState.value {
            Logger.debug("Default shipping details loaded - ID: \(details.id), Name: \(details.fullName ?? "N/A"), Address: \(details.address)")
        }
        
        if case .loaded(let addresses) = shippingAddressesState.value {
            Logger.debug("Shipping addresses loaded - Count: \(addresses.count)")
            for address in addresses {
                Logger.debug("  Address ID: \(address.id), Default: \(address.isDefault ?? false), Address: \(address.address)")
            }
        }
    }
}
