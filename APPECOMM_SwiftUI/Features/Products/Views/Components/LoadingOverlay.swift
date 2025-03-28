//
//  LoadingOverlay.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 3)
                )
        }
        .ignoresSafeArea()
    }
}
