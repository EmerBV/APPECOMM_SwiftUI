//
//  ShippingDetailsSection.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct ShippingDetailsSection: View {
    let details: ShippingDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let fullName = details.fullName {
                Text(fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(details.address ?? "")
                .font(.subheadline)
            
            Text("\(details.city ?? ""), \(details.state ?? "") \(details.postalCode ?? "")")
                .font(.subheadline)
            
            Text(details.country ?? "")
                .font(.subheadline)
            
            if let phoneNumber = details.phoneNumber {
                Text(phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
