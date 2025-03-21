//
//  MainTabView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var profileViewModel = DependencyInjector.shared.resolve(ProfileViewModel.self)
    
    init() {
        
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView(viewModel: DependencyInjector.shared.resolve(HomeViewModel.self))
            }
            .tabItem {
                Image(systemName: "house")
            }
            .tag(0)
            .onAppear {
                Logger.info("HomeView appeared")
            }
            
            NavigationView {
                ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
            }
            .tabItem {
                Image(systemName: "bag")
            }
            .tag(1)
            .onAppear {
                Logger.info("ProductListView appeared")
            }
            
            NavigationView {
                CartView(viewModel: DependencyInjector.shared.resolve(CartViewModel.self))
            }
            .tabItem {
                Image(systemName: "cart")
            }
            .tag(2)
            .onAppear {
                Logger.info("CartView appeared")
            }
            
            NavigationView {
                ProfileView(viewModel: profileViewModel)
            }
            .tabItem {
                if let firstName = profileViewModel.user?.firstName.first {
                    Image(systemName: "\(firstName.lowercased()).circle")
                } else {
                    Image(systemName: "person")
                }
            }
            .tag(3)
            .onAppear {
                Logger.info("ProfileView appeared")
            }
        }
    }
}
