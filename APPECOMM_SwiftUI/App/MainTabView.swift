//
//  MainTabView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        print("MainTabView: Initializing")
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
            }
            .tabItem {
                Label("Products", systemImage: "bag")
            }
            .tag(0)
            .onAppear {
                print("MainTabView: Products tab appeared")
            }
            
            NavigationView {
                Text("Cart Screen")
                    .navigationTitle("My Cart")
            }
            .tabItem {
                Label("Cart", systemImage: "cart")
            }
            .tag(1)
            
            NavigationView {
                ProfileView(viewModel: DependencyInjector.shared.resolve(ProfileViewModel.self))
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(2)
        }
        .onAppear {
            print("MainTabView: TabView appeared")
        }
    }
}
