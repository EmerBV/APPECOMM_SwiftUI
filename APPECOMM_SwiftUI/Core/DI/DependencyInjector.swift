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
                CheckoutAssembly() // Add our new CheckoutAssembly
            ],
            container: container
        )
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolvedType = container.resolve(T.self) else {
            fatalError("Could not resolve type \(String(describing: T.self))")
        }
        return resolvedType
    }
}
