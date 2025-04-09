//
//  ShippingFormSummary.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct ShippingFormSummary: View {
    let form: ShippingDetailsForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(form.fullName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(form.address)
                .font(.subheadline)
            
            Text("\(form.city), \(form.state) \(form.postalCode)")
                .font(.subheadline)
            
            Text(form.country)
                .font(.subheadline)
            
            Text(form.phoneNumber)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

