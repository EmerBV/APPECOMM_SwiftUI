//
//  CheckoutService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//


import Foundation
import Combine

protocol CheckoutServiceProtocol {
    func createOrder(_ order: Order) -> AnyPublisher<Order, NetworkError>
    func getOrder(id: Int) -> AnyPublisher<Order, NetworkError>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, NetworkError>
    func getOrderById(orderId: Int) -> AnyPublisher<Order, NetworkError>
}

final class CheckoutService: CheckoutServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func createOrder(_ order: Order) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.createOrder(order)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .handleEvents(receiveSubscription: { _ in
                Logger.info("CheckoutService: Creating order for user: \(order.userId)")
            }, receiveOutput: { response in
                Logger.info("CheckoutService: Order created successfully: \(response.data.id)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to create order: \(error)")
                }
            })
            .map(\.data)
            .mapError { error -> NetworkError in
                Logger.error("CheckoutService: Order creation error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func getOrder(id: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.getOrder(id: id)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("CheckoutService: Order retrieved successfully: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to get user order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.updateOrderStatus(id: id, status: status)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("CheckoutService: Order status updated successfully: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to update user order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getOrderById(orderId: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = CheckoutEndpoints.getOrder(id: orderId)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("CheckoutService: Order retrieved successfully: \(response.data.id)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("CheckoutService: Failed to get user order: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
} 
