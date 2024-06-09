import SwiftUI
import Firebase

struct FinesManagementView: View {
    @State private var percentageForDamagedBooks: Double?
    @State private var percentageForLostBooks: Double?
    @State private var fixedFineForLateReturns: Double?

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    @Environment(\.colorScheme) var colorScheme // Detect color scheme (light/dark)

    let themeColor = Color(red: 228/255, green: 133/255, blue: 134/255) // Pink color

    let fineDocumentID = "fine_configuration" // Fixed document ID for the fine configuration

    var body: some View {
        NavigationView {
            VStack{
            ScrollView {
                VStack {
                    if let percentageForDamagedBooks = percentageForDamagedBooks,
                       let percentageForLostBooks = percentageForLostBooks,
                       let fixedFineForLateReturns = fixedFineForLateReturns {
                        
                        // Damaged Books
                        FinePercentageField(label: "Damaged Books", percentage: $percentageForDamagedBooks, suffix: "% of the book's amount", themeColor: themeColor, maxPercentage: 100, textColor: colorScheme == .dark ? .white : .black)
                        
                        // Lost Books
                        FinePercentageField(label: "Lost Books", percentage: $percentageForLostBooks, suffix: "% of the book's amount", themeColor: themeColor, maxPercentage: 200, textColor: colorScheme == .dark ? .white : .black)
                        
                        // Late Return of Books
                        FineFixedAmountField(label: "Late Return of Books", amount: $fixedFineForLateReturns, suffix: " per day", themeColor: themeColor, textColor: colorScheme == .dark ? .white : .black)
                    } else {
                        ProgressView("Loading...")
                    }
                }
                .padding()
            }
            
            Spacer() // Add spacer to push the button to the bottom
            
            Button("Save") {
                saveFinesToFirestore()
            }
            .padding()
            .foregroundColor(themeColor)
           
        }
            .navigationBarTitle("Fines Management")
//            .navigationBarItems(trailing: Button("Save") {
//                saveFinesToFirestore()
                    
//            }.foregroundColor(themeColor))
            
            
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            fetchFinesFromFirestore()
        }
    }

    private func fetchFinesFromFirestore() {
        let db = Firestore.firestore()

        db.collection("Fine").document(fineDocumentID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                percentageForDamagedBooks = data?["damagedBooksPercentage"] as? Double
                percentageForLostBooks = data?["lostBooksPercentage"] as? Double
                fixedFineForLateReturns = data?["lateReturnFixedAmount"] as? Double
            } else {
                print("Document does not exist")
            }
        }
    }

    private func saveFinesToFirestore() {
        guard let percentageForDamagedBooks = percentageForDamagedBooks,
              let percentageForLostBooks = percentageForLostBooks,
              let fixedFineForLateReturns = fixedFineForLateReturns else {
            print("Fines data is not available.")
            return
        }

        let db = Firestore.firestore()

        let fineDetails = [
            "damagedBooksPercentage": percentageForDamagedBooks,
            "lostBooksPercentage": percentageForLostBooks,
            "lateReturnFixedAmount": fixedFineForLateReturns
        ]

        // Update existing document with the fixed document ID
        db.collection("Fine").document(fineDocumentID).setData(fineDetails, merge: true) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = "Failed to save fines configuration."
                print("Error updating document: \(error)")
            } else {
                alertTitle = "Success"
                alertMessage = "Fines configuration saved successfully!"
                print("Document updated successfully!")
            }
            showAlert = true
        }
    }
}

struct FinePercentageField: View {
    var label: String
    @Binding var percentage: Double?
    var suffix: String
    let themeColor: Color
    let maxPercentage: Int
    let textColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label)").foregroundColor(themeColor)
            HStack {
                if let percentage = percentage {
                    Text("\(Int(percentage))\(suffix)").foregroundColor(textColor) // Adjust text color based on color scheme
                } else {
                    Text("N/A")
                }
                Spacer()
                Stepper("", value: Binding(
                    get: {
                        percentage ?? 0
                    },
                    set: { newValue in
                        percentage = newValue
                    }), in: 0...Double(maxPercentage), step: 5)
                    .labelsHidden()
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(Color.clear) // Set background color to transparent
        .cornerRadius(10)
    }
}


struct FineFixedAmountField: View {
    var label: String
    @Binding var amount: Double?
    var suffix: String
    let themeColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label)").foregroundColor(themeColor)
            HStack {
                if let amount = amount {
                    Text("₹\(amount, specifier: "%.2f")\(suffix)").foregroundColor(textColor) // Adjust text color based on color scheme
                } else {
                    Text("N/A")
                }
                Spacer()
                Stepper("", value: Binding(
                    get: {
                        amount ?? 0
                    },
                    set: { newValue in
                        amount = newValue
                    }), in: 0...100, step: 1)
                    .labelsHidden()
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(Color.clear) // Set background color to transparent
        .cornerRadius(10)
    }
}

struct FinesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        FinesManagementView()
    }
}
