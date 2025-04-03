//
//  ShippingAddressesViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import Foundation
import Combine

class ShippingAddressesViewModel: ObservableObject {
    @Published var addresses: [ShippingDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedAddress: ShippingDetails?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Inicialización básica
    }
    
    // MARK: - Métodos públicos
    
    func loadShippingAddresses(userId: Int) {
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.getAllShippingAddresses(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load addresses: \(error.localizedDescription)"
                    Logger.error("Error loading shipping addresses: \(error)")
                }
            } receiveValue: { [weak self] addressResponses in
                guard let self = self else { return }
                
                // Convertir ShippingDetailsResponse a ShippingDetails
                self.addresses = addressResponses.map { response in
                    ShippingDetails(
                        id: response.id,
                        address: response.address,
                        city: response.city,
                        state: response.state,
                        postalCode: response.postalCode,
                        country: response.country,
                        phoneNumber: response.phoneNumber,
                        fullName: response.fullName,
                        isDefault: response.isDefault ?? false
                    )
                }
                
                // Seleccionar la dirección predeterminada si existe
                self.selectedAddress = self.addresses.first(where: { $0.isDefault ?? false })
                
                Logger.info("Loaded \(self.addresses.count) shipping addresses")
            }
            .store(in: &cancellables)
    }
    
    func createShippingAddress(form: ShippingDetailsForm) {
        guard let userId = TokenManager.shared.getUserId() else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.createShippingAddress(userId: userId, details: form)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to create address: \(error.localizedDescription)"
                    Logger.error("Error creating shipping address: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                let newAddress = ShippingDetails(
                    id: response.id,
                    address: response.address,
                    city: response.city,
                    state: response.state,
                    postalCode: response.postalCode,
                    country: response.country,
                    phoneNumber: response.phoneNumber,
                    fullName: response.fullName,
                    isDefault: response.isDefault ?? false
                )
                
                // Si esta es la dirección predeterminada, desmarcar la anterior
                if newAddress.isDefault {
                    self.addresses = self.addresses.map { address in
                        var updatedAddress = address
                        if address.id != newAddress.id && address.isDefault {
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
                }
                
                // Insertar nueva dirección
                self.addresses.append(newAddress)
                
                // Si es la única dirección, seleccionarla
                if self.addresses.count == 1 {
                    self.selectedAddress = newAddress
                }
                
                // Si es la dirección predeterminada, seleccionarla
                if newAddress.isDefault {
                    self.selectedAddress = newAddress
                }
                
                Logger.info("Created new shipping address with ID: \(newAddress.id)")
            }
            .store(in: &cancellables)
    }
    
    func updateShippingAddress(id: Int, form: ShippingDetailsForm) {
        guard let userId = TokenManager.shared.getUserId() else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Preparar la solicitud con los datos del formulario e ID
        let request = form.toRequest(id: id)
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.updateShippingAddress(userId: userId, details: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to update address: \(error.localizedDescription)"
                    Logger.error("Error updating shipping address: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                let updatedAddress = ShippingDetails(
                    id: response.id,
                    address: response.address,
                    city: response.city,
                    state: response.state,
                    postalCode: response.postalCode,
                    country: response.country,
                    phoneNumber: response.phoneNumber,
                    fullName: response.fullName,
                    isDefault: response.isDefault ?? false
                )
                
                // Si esta es la dirección predeterminada, desmarcar la anterior
                if updatedAddress.isDefault {
                    self.addresses = self.addresses.map { address in
                        var modifiedAddress = address
                        if address.id != updatedAddress.id && address.isDefault {
                            modifiedAddress = ShippingDetails(
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
                        return modifiedAddress
                    }
                }
                
                // Actualizar la dirección en la lista
                if let index = self.addresses.firstIndex(where: { $0.id == id }) {
                    self.addresses[index] = updatedAddress
                }
                
                // Si es la dirección seleccionada actualmente, actualizarla
                if self.selectedAddress?.id == id {
                    self.selectedAddress = updatedAddress
                }
                
                // Si se ha marcado como predeterminada, seleccionarla
                if updatedAddress.isDefault {
                    self.selectedAddress = updatedAddress
                }
                
                Logger.info("Updated shipping address with ID: \(updatedAddress.id)")
            }
            .store(in: &cancellables)
    }
    
    func deleteShippingAddress(id: Int) {
        guard let userId = TokenManager.shared.getUserId() else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.deleteShippingAddress(userId: userId, addressId: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to delete address: \(error.localizedDescription)"
                    Logger.error("Error deleting shipping address: \(error)")
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                
                // Verificar si se eliminó la dirección predeterminada
                let wasDefault = self.addresses.first(where: { $0.id == id })?.isDefault ?? false
                
                // Eliminar la dirección de la lista
                self.addresses.removeAll { $0.id == id }
                
                // Si era la dirección seleccionada, deseleccionarla
                if self.selectedAddress?.id == id {
                    self.selectedAddress = nil
                }
                
                // Si era la predeterminada y hay más direcciones, establecer la primera como predeterminada
                if wasDefault && !self.addresses.isEmpty && TokenManager.shared.getUserId() != nil {
                    // En un caso real, aquí deberíamos hacer una llamada a la API para establecer
                    // otra dirección como predeterminada
                    if let firstAddressId = self.addresses.first?.id {
                        self.setDefaultShippingAddress(
                            userId: TokenManager.shared.getUserId()!,
                            addressId: firstAddressId
                        )
                    }
                }
                
                Logger.info("Deleted shipping address with ID: \(id)")
            }
            .store(in: &cancellables)
    }
    
    func setDefaultShippingAddress(userId: Int, addressId: Int) {
        isLoading = true
        errorMessage = nil
        
        let shippingRepository = DependencyInjector.shared.resolve(ShippingRepositoryProtocol.self)
        
        shippingRepository.setDefaultShippingAddress(userId: userId, addressId: addressId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to set default address: \(error.localizedDescription)"
                    Logger.error("Error setting default shipping address: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Actualizar todos los flags isDefault en las direcciones
                self.addresses = self.addresses.map { address in
                    var updatedAddress = address
                    updatedAddress.isDefault = (address.id == addressId)
                    return updatedAddress
                }
                
                // Actualizar la dirección seleccionada
                if let newDefaultAddress = self.addresses.first(where: { $0.id == addressId }) {
                    self.selectedAddress = newDefaultAddress
                }
                
                Logger.info("Set address \(addressId) as default for user \(userId)")
            }
            .store(in: &cancellables)
    }
    
    func selectShippingAddress(id: Int) {
        if let address = addresses.first(where: { $0.id == id }) {
            selectedAddress = address
        }
    }
    
    func updateDefaultAddress(_ address: ShippingDetails) {
        guard let index = addresses.firstIndex(where: { $0.id == address.id }) else { return }
        
        // Crear una nueva dirección con isDefault actualizado
        let updatedAddress = ShippingDetails(
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
        
        // Actualizar la dirección en la lista
        addresses[index] = updatedAddress
        
        // Desmarcar todas las demás direcciones como no predeterminadas
        addresses = addresses.map { existingAddress in
            if existingAddress.id != address.id {
                return ShippingDetails(
                    id: existingAddress.id,
                    address: existingAddress.address,
                    city: existingAddress.city,
                    state: existingAddress.state,
                    postalCode: existingAddress.postalCode,
                    country: existingAddress.country,
                    phoneNumber: existingAddress.phoneNumber,
                    fullName: existingAddress.fullName,
                    isDefault: false
                )
            }
            return existingAddress
        }
        
        // Actualizar la dirección seleccionada
        selectedAddress = updatedAddress
    }
}
