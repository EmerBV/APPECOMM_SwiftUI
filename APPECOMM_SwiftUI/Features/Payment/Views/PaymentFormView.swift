import SwiftUI
import Stripe

struct PaymentFormView: View {
    @StateObject private var viewModel = PaymentViewModel()
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvc = ""
    @State private var name = ""
    
    let orderId: Int
    let amount: Double
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("Procesando pago...")
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Detalles de la tarjeta")
                        .font(.headline)
                    
                    TextField("Número de tarjeta", text: $cardNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    HStack {
                        TextField("MM/AA", text: $expiryDate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        TextField("CVC", text: $cvc)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("Nombre en la tarjeta", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: processPayment) {
                        HStack {
                            Text("Pagar")
                            Text(String(format: "%.2f €", amount))
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || viewModel.paymentStatus == .processing)
                }
                .padding()
            }
        }
        .alert(isPresented: .constant(viewModel.paymentStatus == .success)) {
            Alert(
                title: Text("¡Pago exitoso!"),
                message: Text("Tu pago ha sido procesado correctamente."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty &&
        !expiryDate.isEmpty &&
        !cvc.isEmpty &&
        !name.isEmpty
    }
    
    private func processPayment() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardNumber
        cardParams.expMonth = NSNumber(value: UInt(expiryDate.prefix(2)) ?? 0)
        cardParams.expYear = NSNumber(value: UInt(expiryDate.suffix(2)) ?? 0)
        cardParams.cvc = cvc
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = name
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )
        
        viewModel.processPayment(orderId: orderId, card: cardParams)
    }
} 