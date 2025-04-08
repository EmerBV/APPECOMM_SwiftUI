//
//  ToastView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 8/4/25.
//

import SwiftUI

struct ToastView: View {
    var body: some View {
        ZStack {
            VStack {
                VStack(alignment: .center) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                    
                    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                .animation(.bouncy())
            }
            //zIndex(1000)
        }
    }
}

#Preview {
    ToastView()
}
