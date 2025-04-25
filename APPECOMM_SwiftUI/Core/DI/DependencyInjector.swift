//
//  DependencyInjector.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject


/// Central dependency injection manager
final class DependencyInjector {
    static let shared = DependencyInjector()
    
    private let container: Container
    private let assembler: Assembler
    
    private init() {
        container = Container()
        
        // Register all assemblies
        assembler = Assembler(
            [
                NetworkAssembly(),
                StorageAssembly(),
                ServiceAssembly(),
                RepositoryAssembly(),
                ViewModelAssembly(),
                CheckoutAssembly(),
                PaymentAssembly(),
                ShippingAssembly()
            ],
            container: container
        )
    }
    
    /// Resolve a dependency of a specific type
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolvedType = container.resolve(T.self) else {
            fatalError("Could not resolve type \(String(describing: T.self))")
        }
        return resolvedType
    }
    
    /// Resolve a dependency with arguments
    func resolve<T, Arg1>(_ type: T.Type, arguments arg1: Arg1) -> T {
        guard let resolvedType = container.resolve(T.self, argument: arg1) else {
            fatalError("Could not resolve type \(String(describing: T.self)) with argument")
        }
        return resolvedType
    }
    
    /// Resolve a dependency with multiple arguments
    func resolve<T, Arg1, Arg2>(_ type: T.Type, arguments arg1: Arg1, _ arg2: Arg2) -> T {
        guard let resolvedType = container.resolve(T.self, arguments: arg1, arg2) else {
            fatalError("Could not resolve type \(String(describing: T.self)) with arguments")
        }
        return resolvedType
    }
    
    /// Resolve a dependency with three arguments
    func resolve<T, Arg1, Arg2, Arg3>(_ type: T.Type, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> T {
        guard let resolvedType = container.resolve(T.self, arguments: arg1, arg2, arg3) else {
            fatalError("Could not resolve type \(String(describing: T.self)) with arguments")
        }
        return resolvedType
    }
}
