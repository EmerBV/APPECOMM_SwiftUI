//
//  InventoryIndicatorView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct InventoryIndicatorView: View {
    let inventory: Int
    
    private var inventoryLevel: InventoryLevel {
        if inventory <= 0 {
            return .none
        } else if inventory < 5 {
            return .low
        } else if inventory < 10 {
            return .medium
        } else {
            return .high
        }
    }
    
    private enum InventoryLevel {
        case none, low, medium, high
        
        var color: Color {
            switch self {
            case .none: return .red
            case .low: return .orange
            case .medium: return .yellow
            case .high: return .green
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(index < self.inventoryBars ? inventoryLevel.color : Color.gray.opacity(0.3))
                    .frame(height: 6)
                    .cornerRadius(3)
            }
            
            Text("\(inventory) en stock")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
        .frame(maxWidth: 150, alignment: .leading)
    }
    
    private var inventoryBars: Int {
        switch inventoryLevel {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}
