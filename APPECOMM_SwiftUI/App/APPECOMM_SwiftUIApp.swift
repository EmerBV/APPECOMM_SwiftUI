//
//  APPECOMM_SwiftUIApp.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

@main
struct APPECOMM_SwiftUIApp: App {
    // Inicializar dependencias al inicio de la aplicación
    init() {
        // Esto asegura que se inicialice el contenedor de DI
        _ = DependencyInjector.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
