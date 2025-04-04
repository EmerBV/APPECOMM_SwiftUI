//
//  ShippingAddressViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import Foundation
import Combine

// Enum para identificar los campos del formulario
enum FormField {
    case fullName, address, city, state, postalCode, country, phoneNumber
}

class ShippingAddressViewModel: ObservableObject {
    // Estado publicado para la vista
    @Published var form: ShippingDetailsForm = ShippingDetailsForm()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Servicios y repositorios
    private let shippingRepository: ShippingRepositoryProtocol
    private let userId: Int
    private var cancellables = Set<AnyCancellable>()
    
    init(shippingRepository: ShippingRepositoryProtocol, userId: Int) {
        self.shippingRepository = shippingRepository
        self.userId = userId
    }
    
    // Resetear el formulario
    func resetForm() {
        form.reset()
    }
    
    // Cargar los detalles de una dirección existente
    func loadAddressDetails(addressId: Int, forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        // Si forceRefresh es true, hacemos una solicitud específica para obtener datos frescos
        if forceRefresh {
            // Construimos un publisher específico que garantice datos frescos
            let endpoint = ShippingEndpoints.getShippingDetailsById(userId: userId, addressId: addressId)
            let service: ShippingServiceProtocol = DependencyInjector.shared.resolve(ShippingServiceProtocol.self)
            
            service.getShippingDetailsById(userId: userId, addressId: addressId)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<NetworkError>) in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        Logger.error("Error al cargar dirección: \(error)")
                    }
                }, receiveValue: { [weak self] (details: ShippingDetails) in
                    guard let self = self else { return }
                    
                    // Inicializar el formulario con los datos recibidos
                    self.form = ShippingDetailsForm(from: details)
                    Logger.info("Dirección cargada correctamente (forzada): \(details.id ?? 0)")
                })
                .store(in: &cancellables)
            
            return
        }
        
        // Flujo normal si no se fuerza la actualización
        shippingRepository.getShippingAddressById(userId: userId, addressId: addressId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Error al cargar dirección: \(error)")
                }
            }, receiveValue: { [weak self] (details: ShippingDetails) in
                guard let self = self else { return }
                
                // Inicializar el formulario con los datos recibidos
                self.form = ShippingDetailsForm(from: details)
                Logger.info("Dirección cargada correctamente: \(details.id ?? 0)")
            })
            .store(in: &cancellables)
    }
    
    // Validar un campo específico
    func validateField(_ field: FormField) {
        switch field {
        case .fullName:
            form.isFullNameValid = !form.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .address:
            form.isAddressValid = !form.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .city:
            form.isCityValid = !form.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .state:
            form.isStateValid = !form.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .postalCode:
            form.isPostalCodeValid = !form.postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .country:
            form.isCountryValid = !form.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .phoneNumber:
            form.isPhoneNumberValid = !form.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // Validar todo el formulario
    func validateForm() {
        form.validateAll()
    }
    
    // Crear una nueva dirección
    func createAddress(completion: @escaping (Result<ShippingDetails, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Validar formulario primero
        validateForm()
        guard form.isValid else {
            isLoading = false
            errorMessage = "Por favor, completa todos los campos correctamente"
            completion(.failure(NSError(domain: "ShippingAddressViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Formulario inválido"])))
            return
        }
        
        shippingRepository.createShippingAddress(userId: userId, details: form)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                if case .failure(let error) = completionResult {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Error al crear dirección: \(error)")
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] address in
                self?.isLoading = false
                
                // Notificar que la dirección ha sido creada
                NotificationCenter.default.post(name: Notification.Name("ShippingAddressCreated"), object: nil)
                
                Logger.info("Dirección creada correctamente: \(address.id ?? 0)")
                completion(.success(address))
            })
            .store(in: &cancellables)
    }
    
    // Actualizar una dirección existente
    func updateAddress(addressId: Int, completion: @escaping (Result<ShippingDetails, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Validar formulario primero
        validateForm()
        guard form.isValid else {
            isLoading = false
            errorMessage = "Por favor, completa todos los campos correctamente"
            completion(.failure(NSError(domain: "ShippingAddressViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Formulario inválido"])))
            return
        }
        
        // Crear request para actualización
        let request = form.toRequest(id: addressId)
        
        shippingRepository.updateShippingAddress(userId: userId, details: request)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                if case .failure(let error) = completionResult {
                    self?.errorMessage = error.localizedDescription
                    Logger.error("Error al actualizar dirección: \(error)")
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] address in
                self?.isLoading = false
                
                // Notificar que la dirección ha sido actualizada
                NotificationCenter.default.post(name: Notification.Name("ShippingAddressUpdated"), object: nil)
                
                Logger.info("Dirección actualizada correctamente: \(address.id ?? 0)")
                completion(.success(address))
            })
            .store(in: &cancellables)
    }
}
