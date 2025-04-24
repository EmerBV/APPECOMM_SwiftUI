//
//  WishListViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 24/4/25.
//

import Foundation
import Combine

class WishListViewModel: ObservableObject {
    // Published properties
    @Published var wishListItems: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEmpty = false
    
    // Dependencies
    private let wishListRepository: WishListRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(wishListRepository: WishListRepositoryProtocol, authRepository: AuthRepositoryProtocol) {
        self.wishListRepository = wishListRepository
        self.authRepository = authRepository
        
        // Observe repository state changes
        setupObservers()
    }
    
    private func setupObservers() {
        wishListRepository.wishListState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .loading, .updating:
                    self.isLoading = true
                    self.errorMessage = nil
                case .loaded(let wishList):
                    self.isLoading = false
                    self.wishListItems = wishList.products
                    self.isEmpty = wishList.products.isEmpty
                case .empty:
                    self.isLoading = false
                    self.wishListItems = []
                    self.isEmpty = true
                case .error(let message):
                    self.isLoading = false
                    self.errorMessage = message
                case .initial:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func loadWishList() {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "User not authenticated"
            self.isEmpty = true
            return
        }
        
        wishListRepository.getUserWishList(userId: userId)
            .sink { completion in
                // This is handled by the state observer
            } receiveValue: { _ in
                // This is handled by the state observer
            }
            .store(in: &cancellables)
    }
    
    func removeFromWishList(productId: Int) {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        wishListRepository.removeFromWishList(userId: userId, productId: productId)
            .sink { completion in
                // This is handled by the state observer
            } receiveValue: { _ in
                // This is handled by the state observer
            }
            .store(in: &cancellables)
    }
    
    func addToWishList(productId: Int) {
        guard let userId = getCurrentUserId() else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        wishListRepository.addToWishList(userId: userId, productId: productId)
            .sink { completion in
                // This is handled by the state observer
            } receiveValue: { _ in
                // This is handled by the state observer
            }
            .store(in: &cancellables)
    }
    
    func isProductInWishList(productId: Int) -> Bool {
        return wishListRepository.isProductInWishList(productId: productId)
    }
    
    private func getCurrentUserId() -> Int? {
        if case .loggedIn(let user) = authRepository.authState.value {
            return user.id
        }
        return nil
    }
    
    func clearErrorMessage() {
        self.errorMessage = nil
    }
}
