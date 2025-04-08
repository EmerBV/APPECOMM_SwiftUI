import SwiftUI

struct RefreshButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.primary)
        }
    }
} 