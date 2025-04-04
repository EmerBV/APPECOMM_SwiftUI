//
//  ShippingAddressesViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import Foundation
import Combine

class ShippingAddressesViewModel: ObservableObject {
    // Estado publicado
    @Published var addresses: [ShippingDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Dependencias
    private let shippingRepository: ShippingRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(shippingRepository: ShippingRepositoryProtocol) {
        self.shippingRepository = shippingRepository
    }
    
    // MARK: - Public Methods
    
    /// Carga todas las direcciones para un usuario
    /// - Parameter userId: ID del usuario
    func loadAddresses(userId: Int) {
        isLoading = true
        errorMessage = nil
        
        shippingRepository.getAllShippingAddresses(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Error loading shipping addresses: \(error)")
                }
            } receiveValue: { [weak self] addresses in
                self?.addresses = addresses
                Logger.info("Loaded \(addresses.count) shipping addresses")
            }
            .store(in: &cancellables)
    }
    
    /// Establece una dirección como predeterminada
    /// - Parameters:
    ///   - userId: ID del usuario
    ///   - addressId: ID de la dirección a establecer como predeterminada
    func setDefaultAddress(userId: Int, addressId: Int) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        shippingRepository.setDefaultShippingAddress(userId: userId, addressId: addressId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Error setting default address: \(error)")
                }
            } receiveValue: { [weak self] defaultAddress in
                // Actualizar la lista de direcciones
                self?.successMessage = "Default address updated successfully"
                self?.loadAddresses(userId: userId)
                Logger.info("Address \(addressId) set as default")
            }
            .store(in: &cancellables)
    }
    
    /// Elimina una dirección
    /// - Parameters:
    ///   - userId: ID del usuario
    ///   - addressId: ID de la dirección a eliminar
    func deleteAddress(userId: Int, addressId: Int) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        shippingRepository.deleteShippingAddress(userId: userId, addressId: addressId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Error deleting address: \(error)")
                }
            } receiveValue: { [weak self] _ in
                self?.successMessage = "Address deleted successfully"
                self?.loadAddresses(userId: userId)
                Logger.info("Address \(addressId) deleted")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    /// Verifica si una dirección es la predeterminada
    /// - Parameter addressId: ID de la dirección
    /// - Returns: true si es la predeterminada
    func isDefaultAddress(_ addressId: Int?) -> Bool {
        guard let addressId = addressId else { return false }
        return addresses.first { $0.id == addressId }?.isDefault ?? false
    }
    
    /// Obtiene la dirección predeterminada si existe
    /// - Returns: La dirección predeterminada o nil
    func getDefaultAddress() -> ShippingDetails? {
        return addresses.first { $0.isDefault ?? false }
    }
}
