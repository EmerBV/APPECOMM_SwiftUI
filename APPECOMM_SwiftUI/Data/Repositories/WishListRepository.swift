//
//  WishListRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 2/4/25.
//

import Foundation
import Combine

protocol WishListRepositoryProtocol {
    var wishListState: CurrentValueSubject<WishListState, Never> { get }
    
    func getUserWishList(userId: Int) -> AnyPublisher<WishList, Error>
    func addToWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, Error>
    func removeFromWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, Error>
    func isProductInWishList(productId: Int) -> Bool
    func refreshWishList(userId: Int) -> AnyPublisher<WishList, Error>
    
    func debugWishListState()
}

final class WishListRepository: WishListRepositoryProtocol {
    var wishListState: CurrentValueSubject<WishListState, Never> = CurrentValueSubject(.initial)
    
    private let wishListService: WishListServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(wishListService: WishListServiceProtocol) {
        self.wishListService = wishListService
    }
    
    func getUserWishList(userId: Int) -> AnyPublisher<WishList, Error> {
        Logger.info("WishListRepository: Getting wishlist for user: \(userId)")
        wishListState.send(.loading)
        
        return wishListService.getUserWishList(userId: userId)
            .handleEvents(receiveOutput: { [weak self] wishList in
                Logger.info("WishListRepository: Received wishlist with \(wishList.products.count) products")
                if wishList.products.isEmpty {
                    self?.wishListState.send(.empty)
                } else {
                    self?.wishListState.send(.loaded(wishList))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListRepository: Failed to get wishlist: \(error)")
                    self?.wishListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func addToWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, Error> {
        Logger.info("WishListRepository: Adding product to wishlist - userId: \(userId), productId: \(productId)")
        wishListState.send(.updating)
        
        return wishListService.addToWishList(userId: userId, productId: productId)
            .handleEvents(receiveOutput: { [weak self] wishList in
                Logger.info("WishListRepository: Product added to wishlist successfully")
                self?.wishListState.send(.loaded(wishList))
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListRepository: Failed to add product to wishlist: \(error)")
                    self?.refreshWishListAfterError(userId: userId)
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func removeFromWishList(userId: Int, productId: Int) -> AnyPublisher<WishList, Error> {
        Logger.info("WishListRepository: Removing product from wishlist - userId: \(userId), productId: \(productId)")
        wishListState.send(.updating)
        
        return wishListService.removeFromWishList(userId: userId, productId: productId)
            .handleEvents(receiveOutput: { [weak self] wishList in
                Logger.info("WishListRepository: Product removed from wishlist successfully")
                if wishList.products.isEmpty {
                    self?.wishListState.send(.empty)
                } else {
                    self?.wishListState.send(.loaded(wishList))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListRepository: Failed to remove product from wishlist: \(error)")
                    self?.refreshWishListAfterError(userId: userId)
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func isProductInWishList(productId: Int) -> Bool {
        if case .loaded(let wishList) = wishListState.value {
            return wishList.products.contains(where: { $0.id == productId })
        }
        return false
    }
    
    func refreshWishList(userId: Int) -> AnyPublisher<WishList, Error> {
        Logger.info("WishListRepository: Refreshing wishlist for user: \(userId)")
        
        return wishListService.getUserWishList(userId: userId)
            .handleEvents(receiveOutput: { [weak self] wishList in
                Logger.info("WishListRepository: Wishlist refreshed with \(wishList.products.count) products")
                if wishList.products.isEmpty {
                    self?.wishListState.send(.empty)
                } else {
                    self?.wishListState.send(.loaded(wishList))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListRepository: Failed to refresh wishlist: \(error)")
                    self?.wishListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    private func refreshWishListAfterError(userId: Int) {
        wishListService.getUserWishList(userId: userId)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("WishListRepository: Failed to recover wishlist state: \(error)")
                    self?.wishListState.send(.error(error.localizedDescription))
                }
            }, receiveValue: { [weak self] wishList in
                if wishList.products.isEmpty {
                    self?.wishListState.send(.empty)
                } else {
                    self?.wishListState.send(.loaded(wishList))
                }
            })
            .store(in: &cancellables)
    }
    
    func debugWishListState() {
        Logger.debug("Current wishlist state: \(wishListState.value)")
        
        if case .loaded(let wishList) = wishListState.value {
            Logger.debug("WishList ID: \(wishList.id), User ID: \(wishList.userId), Products: \(wishList.products.count)")
            for product in wishList.products {
                Logger.debug("Product: \(product.id) - \(product.name)")
            }
        }
    }
}
