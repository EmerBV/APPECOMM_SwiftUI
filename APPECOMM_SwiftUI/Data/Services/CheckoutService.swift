//
//  CheckoutService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//


import Foundation
import Combine

protocol CheckoutServiceProtocol {
    func createOrder(userId: Int, shippingDetailsId: Int) -> AnyPublisher<Order, NetworkError>
    func getOrder(id: Int) -> AnyPublisher<Order, NetworkError>
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], NetworkError>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, NetworkError>
}

final class CheckoutService: CheckoutServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func createOrder(userId: Int, shippingDetailsId: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.createOrder(userId: userId, shippingDetailsId: shippingDetailsId)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .handleEvents(receiveSubscription: { _ in
                Logger.info("CheckoutService: Creating order for user: \(userId) with shipping details ID: \(shippingDetailsId)")
            }, receiveOutput: { response in
                Logger.info("CheckoutService: Order created successfully: \(response.data.id)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to create order: \(error)")
                }
            })
            .map(\.data)
            .eraseToAnyPublisher()
    }
    
    func getOrder(id: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.getOrderById(orderId: id)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("CheckoutService: Order retrieved successfully: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to get order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], NetworkError> {
        let endpoint = CheckoutEndpoints.getUserOrders(userId: userId)
        
        return networkDispatcher.dispatch(ApiResponse<[Order]>.self, endpoint)
            .map { response -> [Order] in
                Logger.info("CheckoutService: Successfully fetched orders: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to get orders: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.updateOrderStatus(orderId: id, status: status)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("CheckoutService: Order status updated successfully: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to update order status: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
