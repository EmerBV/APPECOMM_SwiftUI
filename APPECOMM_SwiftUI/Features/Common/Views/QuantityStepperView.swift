import SwiftUI

struct QuantityStepperView: View {
    @Binding var quantity: Int
    let range: ClosedRange<Int>
    let onValueChanged: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if quantity > range.lowerBound {
                    quantity -= 1
                    onValueChanged(quantity)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(quantity > range.lowerBound ? .accentColor : .gray)
            }
            .disabled(quantity <= range.lowerBound)
            .buttonStyle(PlainButtonStyle())
            
            Text("\(quantity)")
                .font(.headline)
                .frame(minWidth: 30)
            
            Button {
                if quantity < range.upperBound {
                    quantity += 1
                    onValueChanged(quantity)
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(quantity < range.upperBound ? .accentColor : .gray)
            }
            .disabled(quantity >= range.upperBound)
            .buttonStyle(PlainButtonStyle())
        }
    }
} 