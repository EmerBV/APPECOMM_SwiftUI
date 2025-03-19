//
//  AuthDebugView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI
import Combine

struct AuthDebugView: View {
    @ObservedObject var authDebugger: AuthDebugger
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Auth Debugger")
                .font(.title)
                .padding(.bottom)
            
            Text("Current State: \(authDebugger.currentState)")
                .font(.headline)
            
            if let userId = authDebugger.userId {
                Text("User ID: \(userId)")
            }
            
            if let token = authDebugger.token {
                Text("Token: \(token.prefix(15))...")
            }
            
            if let error = authDebugger.lastError {
                Text("Last Error: \(error)")
                    .foregroundColor(.red)
            }
            
            Divider()
            
            Button("Force Login State") {
                authDebugger.forceLoginState()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Force Logout State") {
                authDebugger.forceLogoutState()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Check Token") {
                authDebugger.checkToken()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

class AuthDebugger: ObservableObject {
    @Published var currentState: String = "Unknown"
    @Published var userId: Int?
    @Published var token: String?
    @Published var lastError: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol, tokenManager: TokenManagerProtocol) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        
        authRepository.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .loggedIn(let user):
                    self?.currentState = "LoggedIn"
                    self?.userId = user.id
                case .loggedOut:
                    self?.currentState = "LoggedOut"
                    self?.userId = nil
                case .loading:
                    self?.currentState = "Loading"
                }
            }
            .store(in: &cancellables)
        
        checkToken()
    }
    
    func checkToken() {
        token = tokenManager.getAccessToken()
    }
    
    func forceLoginState() {
        // Crear un usuario ficticio
        let user = User(
            id: 999,
            firstName: "Debug",
            lastName: "User",
            email: "debug@example.com",
            shippingDetails: nil,
            cart: nil,
            orders: nil
        )
        
        // Enviar estado de login directamente
        if let authRepoWithPublisher = authRepository as? AuthRepository {
            authRepoWithPublisher.authState.send(.loggedIn(user))
        }
        
        // También enviamos la notificación como respaldo
        NotificationCenter.default.post(name: Notification.Name("UserLoggedIn"), object: user)
    }
    
    func forceLogoutState() {
        if let authRepoWithPublisher = authRepository as? AuthRepository {
            authRepoWithPublisher.authState.send(.loggedOut)
        }
    }
}
