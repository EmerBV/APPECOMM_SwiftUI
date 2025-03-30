import Foundation
import Combine

protocol CheckoutServiceProtocol {
    func createOrder(_ order: Order) -> AnyPublisher<Order, Error>
    func getOrder(id: Int) -> AnyPublisher<Order, Error>
    func updateOrderStatus(id: Int, status: String) -> AnyPublisher<Order, Error>
} 