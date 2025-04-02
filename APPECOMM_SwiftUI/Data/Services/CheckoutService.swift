import Foundation
import Combine

protocol CheckoutServiceProtocol {
    func createOrder(_ order: Order) -> AnyPublisher<Order, Error>
    func getOrder(id: Int) -> AnyPublisher<Order, Error>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error>
} 

final class CheckoutService: CheckoutServiceProtocol {
    private let networkDispatcher: NetworkDispatcherProtocol
    
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func createOrder(_ order: Order) -> AnyPublisher<Order, Error> {
        let endpoint = CheckoutEndpoints.createOrder(order)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .handleEvents(receiveSubscription: { _ in
                Logger.info("Creating order for user: \(order.userId)")
            }, receiveOutput: { response in
                Logger.info("Order created successfully: \(response.data.id)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Failed to create order: \(error)")
                }
            })
            .map(\.data)
            .mapError { error -> Error in
                Logger.error("Order creation error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func getOrder(id: Int) -> AnyPublisher<Order, Error> {
        let endpoint = CheckoutEndpoints.getOrder(id: id)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("Order retrieved successfully: \(response.data.id)")
                return response.data
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error> {
        let endpoint = CheckoutEndpoints.updateOrderStatus(id: id, status: status)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("Order status updated successfully: \(response.data.id)")
                return response.data
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getOrderById(orderId: Int) -> AnyPublisher<Order, Error> {
        let endpoint = CheckoutEndpoints.getOrder(id: orderId)
        
        return networkDispatcher.dispatch(ApiResponse<Order>.self, endpoint)
            .map { response -> Order in
                Logger.info("Order retrieved successfully: \(response.data.id)")
                return response.data
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
} 
