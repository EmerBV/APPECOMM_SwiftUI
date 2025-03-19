//
//  DependencyInjector.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Swinject

/// Gestor central de inyección de dependencias
final class DependencyInjector {
    static let shared = DependencyInjector()
    
    private let container: Container
    private let assembler: Assembler
    
    private init() {
        container = Container()
        
        // Registrar todos los ensambladores
        assembler = Assembler(
            [
                NetworkAssembly(),
                StorageAssembly(),
                ServiceAssembly(),
                RepositoryAssembly(),
                ViewModelAssembly()
            ],
            container: container
        )
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolvedType = container.resolve(T.self) else {
            fatalError("No se pudo resolver el tipo \(String(describing: T.self))")
        }
        return resolvedType
    }
}
