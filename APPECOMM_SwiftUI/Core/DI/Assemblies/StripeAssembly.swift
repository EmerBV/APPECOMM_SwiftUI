//
//  StripeAssembly.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
import Swinject

class StripeAssembly: Assembly {
    func assemble(container: Container) {
        container.register(StripeServiceProtocol.self) { _ in
            StripeService()
        }.inObjectScope(.container)
    }
}
