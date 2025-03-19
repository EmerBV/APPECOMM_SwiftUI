//
//  ProfileViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    // Published properties
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Edit profile form fields
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    
    // Edit profile form state
    @Published var isEditingProfile = false
    @Published var isSavingProfile = false
    
    // Field validation states
    @Published var firstNameState: FieldState = .normal
    @Published var lastNameState: FieldState = .normal
    
    private let userRepository: UserRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userRepository: UserRepositoryProtocol, authRepository: AuthRepositoryProtocol) {
        self.userRepository = userRepository
        self.authRepository = authRepository
        
        // Observar cambios en el estado de autenticación
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case let .loggedIn(user) = state {
                    self?.user = user
                    self?.firstName = user.firstName
                    self?.lastName = user.lastName
                } else {
                    self?.user = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func loadUserProfile() {
        guard let userId = user?.id else {
            errorMessage = "No user ID available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        userRepository.getUserProfile(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                self?.user = user
                self?.firstName = user.firstName
                self?.lastName = user.lastName
            }
            .store(in: &cancellables)
    }
    
    func validateFirstName() {
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            firstNameState = .invalid("First name cannot be empty")
        } else {
            firstNameState = .valid
        }
    }
    
    func validateLastName() {
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastNameState = .invalid("Last name cannot be empty")
        } else {
            lastNameState = .valid
        }
    }
    
    var isFormValid: Bool {
        if case .invalid = firstNameState { return false }
        if case .invalid = lastNameState { return false }
        return !firstName.isEmpty && !lastName.isEmpty
    }
    
    func saveProfile() {
        guard let userId = user?.id else {
            errorMessage = "No user ID available"
            return
        }
        
        validateFirstName()
        validateLastName()
        
        guard isFormValid else { return }
        
        isSavingProfile = true
        errorMessage = nil
        
        userRepository.updateUserProfile(
            userId: userId,
            firstName: firstName,
            lastName: lastName
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isSavingProfile = false
            
            if case .failure(let error) = completion {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.isEditingProfile = false
            }
        } receiveValue: { [weak self] user in
            self?.user = user
        }
        .store(in: &cancellables)
    }
    
    func cancelEditing() {
        // Reset form fields to current user values
        if let user = user {
            firstName = user.firstName
            lastName = user.lastName
        }
        
        // Reset field states
        firstNameState = .normal
        lastNameState = .normal
        
        // Exit edit mode
        isEditingProfile = false
    }
    
    func logout() {
        authRepository.logout()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in
                // Logout handled by authRepository state
            }
            .store(in: &cancellables)
    }
}
