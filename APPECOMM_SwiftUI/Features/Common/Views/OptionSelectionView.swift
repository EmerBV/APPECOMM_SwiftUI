//
//  OptionSelectionView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 12/5/25.
//

import SwiftUI

// Helper struct for option selection
struct OptionItem: Identifiable {
    let id: String
    let title: String
}

// Generic view for selecting options from a list
struct OptionSelectionView: View {
    let title: String
    let options: [OptionItem]
    let selectedId: String?
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options) { option in
                    Button(action: {
                        onSelect(option.id)
                    }) {
                        HStack {
                            Text(option.title)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if option.id == selectedId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}
