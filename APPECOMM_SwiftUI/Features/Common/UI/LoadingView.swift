//
//  LoadingView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment:.center, spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("loading".localized)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            
            // Dejar este código por si en el futuro queremos encapsular el loading dentro de un rectángulo
            /*
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 10)
            )
             */
          
        }
        .ignoresSafeArea()
    }
}

/*
 #Preview {
 LoadingView()
 }
 */
