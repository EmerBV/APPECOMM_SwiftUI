import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    // Estados principales de la aplicación
    @Published var authState: AuthState = .loggedOut
    @Published var cartState: CartState = .initial
    @Published var wishListState: WishListState = .initial
    
    // Estado de la red
    @Published var networkActivity: Bool = false
    
    // Alertas y mensajes
    @Published var currentAlert: AlertItem?
    
    // Estado de la UI
    @Published var languageChanged = false
    
    private var cancelBag = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
        setupSubscriptions()
    }
    
    func refreshData() {
        Logger.info("Refreshing app data...")
    }
    
    func showSuccessMessage(_ message: String, title: String = "Success") {
        currentAlert = AlertItem(
            title: title,
            message: message,
            dismissButton: .default(Text("OK"))
        )
    }
    
    func showErrorMessage(_ message: String, title: String = "Error") {
        currentAlert = AlertItem(
            title: title,
            message: message,
            dismissButton: .default(Text("OK"))
        )
    }
    
    private func setupNotifications() {
        // Configurar observadores de notificaciones
        NotificationCenter.default.publisher(for: Notification.Name("UserLoggedIn"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancelBag)
        
        // Observar cambios de idioma
        NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.languageChanged.toggle()
                Logger.info("Language changed, forcing view refresh")
            }
            .store(in: &cancelBag)
    }
    
    private func setupSubscriptions() {
        // Observar cambios de autenticación para actualizar el carrito y la lista de deseos
        $authState
            .sink { [weak self] state in
                switch state {
                case .loggedOut:
                    self?.cartState = .initial
                    self?.wishListState = .initial
                case .loading:
                    // Puedes mostrar un indicador de actividad global si lo necesitas
                    self?.networkActivity = true
                case .loggedIn:
                    self?.networkActivity = false
                    // Podrías iniciar la carga del carrito y wishlist aquí si lo deseas
                }
            }
            .store(in: &cancelBag)
    }
}
