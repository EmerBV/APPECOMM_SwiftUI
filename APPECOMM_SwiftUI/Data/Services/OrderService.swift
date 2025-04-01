//
//  OrderService.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

import Foundation
import Combine

protocol OrderServiceProtocol {
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], NetworkError>
    func getOrderById(id: Int) -> AnyPublisher<Order, NetworkError>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, NetworkError>
}

final class OrderService: OrderServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], NetworkError> {
        let endpoint = OrderEndpoints.getUserOrders(userId: userId)
        
        return networkDispatcher.dispatch(ApiResponse<[Order]>.self, endpoint)
            .map { response -> [Order] in
                Logger.info("OrderService: Successfully fetch Orders: \(response.message)")
                return response.data
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("OrderService: Failed to get Orders: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getOrderById(id: Int) -> AnyPublisher<Order, NetworkError> {
        let endpoint = OrderEndpoints.getOrderById(orderId: id)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, NetworkError> {
        let endpoint = OrderEndpoints.updateOrderStatus(orderId: id, status: status)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                return response.data
            }
            .eraseToAnyPublisher()
    }
}
