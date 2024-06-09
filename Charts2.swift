//
//  Charts2.swift
//  LMS3
//
//  Created by Aditya Majumdar on 08/05/24.
//

import SwiftUI
import FirebaseFirestore // Import Firestore module

extension Color {
    static let customPink = Color(hex: 0xE48587)
    
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

struct Bar: Identifiable {
    let id = UUID()
    var name: String
    var day: String
    var value: Double
    var color: Color
    
    static var sampleBars: [Bar] {
        return [
            Bar(name: "1", day: "M", value: 120.0, color: .customPink),
            Bar(name: "2", day: "T", value: 90.0, color: .customPink),
            Bar(name: "3", day: "W", value: 150.0, color: .customPink),
            Bar(name: "4", day: "T", value: 180.0, color: .customPink),
            Bar(name: "5", day: "F", value: 100.0, color: .customPink),
            Bar(name: "6", day: "S", value: 60.0, color: .customPink),
            Bar(name: "7", day: "S", value: 200.0, color: .customPink)
        ]
    }
}

struct Chart2: View {
    @State private var bars: [Bar] = []
    @State private var selectedID: UUID = UUID()
    let scaleFactor: CGFloat = 30.0
    
    var body: some View {
        VStack {
            
            HStack(alignment: .bottom) {
                ForEach(bars) { bar in
                    VStack {
                        Text("\(Int(bar.value))")
                        ZStack {
                            Rectangle()
                                .foregroundColor(bar.color)
                                .frame(width: 35, height: bar.value * scaleFactor, alignment: .bottom)
                                .opacity(selectedID == bar.id ? 0.5 : 1.0)
                                .cornerRadius(6)
                                
                           
                        }
                        Text(bar.day) // Displaying only day and month
                    }
                    
                }
            }
            .frame(height:240, alignment: .bottom)
            .padding(20)
            .background(.thinMaterial)
            .cornerRadius(6)
            .padding()
        }
        .onAppear {
            // Fetch data from Firestore when the view appears
            fetchDataFromFirestore()
        }
    }
    
    func fetchDataFromFirestore() {
        // Access Firestore and fetch data
        let db = Firestore.firestore()
        
        // Assuming your Firestore collection is named "checkindetails"
        db.collection("checkindetails").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                var bookCountsByDay: [String: Int] = [:] // Dictionary to store book counts by day
                
                // Iterate through documents to aggregate book counts by day
                for document in querySnapshot!.documents {
                    // Assuming checkInDate is stored as a String in Firestore
                    if let checkInDate = document.data()["checkInDate"] as? String {
                        // Extract day and month from the full date string (assuming format dd/MM/yyyy)
                        let components = checkInDate.split(separator: "/")
                        let dayMonth = "\(components[0])/\(components[1])"
                        
                        // Increment book count for the corresponding day
                        if let count = bookCountsByDay[dayMonth] {
                            bookCountsByDay[dayMonth] = count + 1
                        } else {
                            bookCountsByDay[dayMonth] = 1
                        }
                    }
                }
                
                // Create Bar objects based on aggregated data
                var fetchedBars: [Bar] = []
                for (dayMonth, count) in bookCountsByDay {
                    let bar = Bar(name: dayMonth, day: dayMonth, value: Double(count), color: .customPink)
                    fetchedBars.append(bar)
                }
                
                // Sort fetched bars based on day
                // Sort fetched bars based on day and month
                fetchedBars.sort { bar1, bar2 in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM"
                    
                    if let date1 = dateFormatter.date(from: bar1.day), let date2 = dateFormatter.date(from: bar2.day) {
                        return date1 < date2
                    } else {
                        return false
                    }
                }

                
                // Update the @State variable to trigger a view refresh with fetched data
                self.bars = fetchedBars
            }
        }
    }
}


struct Chart2_Previews: PreviewProvider {
    static var previews: some View {
        Chart2()
    }
}
