//
//  OrderRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 1/4/25.
//

import Foundation
import Combine

protocol OrderRepositoryProtocol {
    var orderListState: CurrentValueSubject<OrderListState, Never> { get }
    var orderDetailState: CurrentValueSubject<OrderDetailState, Never> { get }
    
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], Error>
    func getOrderById(id: Int) -> AnyPublisher<Order, Error>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error>
    func refreshOrders(userId: Int) -> AnyPublisher<[Order], Error>
    
    func debugOrderState()
}

final class OrderRepository: OrderRepositoryProtocol {
    var orderListState: CurrentValueSubject<OrderListState, Never> = CurrentValueSubject(.initial)
    var orderDetailState: CurrentValueSubject<OrderDetailState, Never> = CurrentValueSubject(.initial)
    
    private let checkoutService: CheckoutServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(checkoutService: CheckoutServiceProtocol) {
        self.checkoutService = checkoutService
    }
    
    func getUserOrders(userId: Int) -> AnyPublisher<[Order], Error> {
        Logger.info("OrderRepository: Getting orders for user: \(userId)")
        orderListState.send(.loading)
        
        return checkoutService.getOrder(id: userId)
            .handleEvents(receiveOutput: { [weak self] orders in
                Logger.info("OrderRepository: Received \(orders.count) orders")
                if orders.isEmpty {
                    self?.orderListState.send(.empty)
                } else {
                    self?.orderListState.send(.loaded(orders))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("OrderRepository: Failed to get orders: \(error)")
                    self?.orderListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getOrderById(id: Int) -> AnyPublisher<Order, Error> {
        Logger.info("OrderRepository: Getting order details for ID: \(id)")
        orderDetailState.send(.loading)
        
        return checkoutService.getOrderById(orderId: id)
            .handleEvents(receiveOutput: { [weak self] order in
                Logger.info("OrderRepository: Received order details for ID: \(order.id)")
                self?.orderDetailState.send(.loaded(order))
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("OrderRepository: Failed to get order details: \(error)")
                    self?.orderDetailState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error> {
        Logger.info("OrderRepository: Updating order status - ID: \(id), Status: \(status)")
        orderDetailState.send(.loading)
        
        return checkoutService.updateOrderStatus(id: id, status: status)
            .handleEvents(receiveOutput: { [weak self] order in
                Logger.info("OrderRepository: Order status updated successfully: \(order.id)")
                self?.orderDetailState.send(.loaded(order))
                
                // Refrescar también la lista de pedidos si está cargada
                if case .loaded(let orders) = self?.orderListState.value {
                    var updatedOrders = orders
                    if let index = updatedOrders.firstIndex(where: { $0.id == order.id }) {
                        updatedOrders[index] = order
                        self?.orderListState.send(.loaded(updatedOrders))
                    }
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("OrderRepository: Failed to update order status: \(error)")
                    self?.orderDetailState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func refreshOrders(userId: Int) -> AnyPublisher<[Order], Error> {
        Logger.info("OrderRepository: Refreshing orders for user: \(userId)")
        
        return checkoutService.getOrder(id: userId)
            .handleEvents(receiveOutput: { [weak self] orders in
                Logger.info("OrderRepository: Orders refreshed: \(orders.count) orders")
                if orders.isEmpty {
                    self?.orderListState.send(.empty)
                } else {
                    self?.orderListState.send(.loaded(orders))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("OrderRepository: Failed to refresh orders: \(error)")
                    self?.orderListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func debugOrderState() {
        Logger.debug("Current order list state: \(orderListState.value)")
        Logger.debug("Current order detail state: \(orderDetailState.value)")
        
        if case .loaded(let orders) = orderListState.value {
            Logger.debug("Loaded \(orders.count) orders")
            for order in orders {
                Logger.debug("Order ID: \(order.id), Status: \(order.status), Total: \(order.totalAmount)")
            }
        }
        
        if case .loaded(let order) = orderDetailState.value {
            Logger.debug("Current order details - ID: \(order.id), Status: \(order.status), Items: \(order.items.count)")
            for item in order.items {
                Logger.debug("Item: \(item.productName), Quantity: \(item.quantity), Price: \(item.price)")
            }
        }
    }
}

