import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
    }
    
    func refreshData() {
        // Implementar lógica de actualización de datos
        Logger.info("Refreshing app data...")
    }
    
    private func setupNotifications() {
        // Configurar observadores de notificaciones
        NotificationCenter.default.publisher(for: Notification.Name("UserLoggedIn"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }
} 