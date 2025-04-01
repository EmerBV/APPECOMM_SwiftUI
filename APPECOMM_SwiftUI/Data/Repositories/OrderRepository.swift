//
//  OrderRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

import Foundation
import Combine

protocol OrderRepositoryProtocol {
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], Error>
    func getOrderById(id: Int) -> AnyPublisher<Order, Error>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error>
}

final class OrderRepository: OrderRepositoryProtocol {
    private let orderService: OrderServiceProtocol
    
    init(orderService: OrderServiceProtocol) {
        self.orderService = orderService
    }
    
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], Error> {
        return orderService.getUserOrders(userId: userId)
            .handleEvents(receiveOutput: { orders in
                print("OrderRepository: Received \(orders.count) orders")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("OrderRepository: Failed to get products: \(error)")
                } else {
                    print("OrderRepository: Successfully completed orders request")
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getOrderById(id: Int) -> AnyPublisher<Order, Error> {
        return orderService.getOrderById(id: id)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error> {
        return orderService.updateOrderStatus(id: id, status: status)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
    
