//
//  Charts.swift
//  LMS3
//
//  Created by Aditya Majumdar on 08/05/24.
//

import SwiftUI
import FirebaseFirestore
import Charts

struct MacroData {
    let name: String
    let value: Int
}


struct CheckinDetails: Identifiable {
    var id: String
    var checkInDate: String
}

struct RatingDetails: Identifiable {
    var id: String
    var isbn: String
    var ratings: [Int]
}

struct Analytics: View {
    @State private var checkinDetails = [CheckinDetails]()
    @State private var ratingDetails = [RatingDetails]()
    @State private var dataPoints: [String: Int] = [:]
    @State private var usersCount: Int = 0
    @State private var maxValue: Int = 0
    @State private var categoryRatings: [String: Int] = [:]
    @State private var macros: [MacroData] = []
    @State private var finesData: [Double] = []
    @State private var labels: [String] = []
    @State private var lastWeekFinesData: [Double] = []
    
    private let collectionName = "checkindetails" // Change this to your Firestore collection name
    private let usersCollectionName = "Users" // Change this to your Firestore users collection name
    private let bookRatingCollectionName = "BookRating" // Change this to your Firestore BookRating collection name
    private let booksCollectionName = "books" // Change this to your Firestore books collection name
    
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(alignment:.leading){
                    VStack{
                        if !dataPoints.isEmpty {
                            BarChartView(dataPoints: dataPoints, usersCount: usersCount, maxValue: maxValue)
                        } else {
                            ProgressView()
                        }
                    }
                    VStack(alignment:.leading){
                        Text("Issues Per day")
                            .font(.title2).bold()
                            .padding(.leading)
                        VStack(){
                            Chart2()
                        }.padding(.leading,60)
                    }
                    
                    
                    VStack(alignment:.leading){
                        Text("Most Rated Categories")
                            .font(.title2).bold()
                            .padding(.leading)
                        VStack{
                            
                            if !categoryRatings.isEmpty {
                                CategoryChartView(categoryRatings: categoryRatings)
                            } else {
                                ProgressView()
                            }
                        }
                    }
                    
                    VStack (alignment: .leading) {
                        Text("Most Issued Categories")
                            .font(.title2).bold()
                        
                        VStack{
                            if !macros.isEmpty { // Show chart only if data is available
                                Chart(macros, id: \.name) { macro in
                                    SectorMark(
                                        angle: .value("Macros", macro.value),
                                        innerRadius: .ratio(0.508)
                                    )
                                    .foregroundStyle(by: .value("Name", macro.name))
                                }
                                .frame(height: 200)
                                .chartXAxis(.hidden)
                            } else {
                                Text("Loading...") // Show loading indicator while data is being fetched
                            }
                        }.padding(20)
                            .background(.thinMaterial)
                            .cornerRadius(6)
                            .padding()
                        
                    }
                    .padding()
                    .onAppear {
                        fetchMacroData() // Fetch data when the view appears
                    }
                    
                    
                    
                    VStack(alignment:.leading){
                        Text("Weekly Fines")
                            .font(.title2).bold()
                            .padding()
                        VStack{
                            if !finesData.isEmpty {
                                // Calculate average increase percentage
                                let averageIncreasePercentage = calculateAverageIncreasePercentage()
                                Text("Fine amount from last week per day")
                                
                                LineChart(dataPoints: finesData, labels: labels)
                                    .frame(height: 300) // Fixed height for the LineChart view
                            } else {
                                ProgressView()
                            }
                        }.padding(20)
                        .background(.thinMaterial)
                        .cornerRadius(6)
                        .padding()
                    }
                    .onAppear {
                        fetchData()
                    }
                    
                    
                }
                .onAppear {
                    resetState()
                    fetchCheckinDetails()
                    fetchUsersCount()
                    fetchBookRatings()
                }
            }.navigationTitle("Analytics")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
    
    private func resetState() {
        checkinDetails.removeAll()
        ratingDetails.removeAll()
        dataPoints.removeAll()
        usersCount = 0
        maxValue = 0
        categoryRatings.removeAll()
        macros.removeAll()
        finesData.removeAll()
        labels.removeAll()
        lastWeekFinesData.removeAll()
    }
    
    func fetchData() {
        let db = Firestore.firestore()
        let fineDetailsRef = db.collection("FineDetails").whereField("fineStatus", isEqualTo: "Paid")

        // Fetch data from Firestore
        fineDetailsRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                var finesByDay: [String: Double] = [:] // Dictionary to store fines by day

                for document in querySnapshot!.documents {
                    if let fineAmountString = document.data()["fineAmount"] as? String,
                       let fineAmount = Double(fineAmountString),
                       let dateString = document.data()["Date"] as? String,
                       let date = dateFormatter.date(from: dateString) {
                        
                        let dayString = dateFormatter.string(from: date) // Get day in string format

                        // Aggregate fine amounts for the same day
                        if let existingFine = finesByDay[dayString] {
                            finesByDay[dayString] = existingFine + fineAmount
                        } else {
                            finesByDay[dayString] = fineAmount
                        }
                    }
                }

                // Convert dictionary to array of tuples (day, fine) and sort by date
                // Convert dictionary to array of tuples (day, fine) and sort by date
                let sortedData = finesByDay.sorted { (entry1, entry2) -> Bool in
                    // Parse dates from keys
                    guard let date1 = dateFormatter.date(from: entry1.key),
                          let date2 = dateFormatter.date(from: entry2.key) else {
                        return false // Unable to parse dates, so return false
                    }
                    
                    // Compare dates by day and month
                    let components1 = Calendar.current.dateComponents([.day, .month], from: date1)
                    let components2 = Calendar.current.dateComponents([.day, .month], from: date2)
                    
                    if let day1 = components1.day, let month1 = components1.month,
                       let day2 = components2.day, let month2 = components2.month {
                        if month1 != month2 { // If months are different, sort by month
                            return month1 < month2
                        } else { // If months are the same, sort by day
                            return day1 < day2
                        }
                    } else {
                        return false // Unable to get day or month components, so return false
                    }
                }


                // Extract fines and labels from sorted data
                finesData = sortedData.map { $0.value }
                labels = sortedData.map { $0.key }

                // Example: Last week's fines data
                lastWeekFinesData = finesData.map { $0 * 0.9 } // Assuming a 10% decrease

                // Update labels to only display dd/MM format
                labels = labels.map { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM"
                    return formatter.string(from: dateFormatter.date(from: date)!)
                }
            }
        }
    }



    func calculateAverageIncreasePercentage() -> Int {
        guard lastWeekFinesData.count == finesData.count, !lastWeekFinesData.contains(where: { $0 == 0 }) else { return 0 }

        let totalIncrease = zip(finesData, lastWeekFinesData).reduce(0) { (result, values) in
            let percentageIncrease: Double
            if values.1 == 0 { // Handle division by zero
                percentageIncrease = values.0.isFinite ? 100 : 0 // Set percentage to 100 if current value is non-zero and last week's value is zero, otherwise set it to 0
            } else {
                percentageIncrease = ((values.0 - values.1) / values.1) * 100
            }
            return result + percentageIncrease
        }

        return Int(totalIncrease) / finesData.count
    }

    
    
    func fetchMacroData() {
        let db = Firestore.firestore()
        db.collection("checkindetails").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                return
            }
            
            var categoryCounts: [String: Int] = [:] // Dictionary to store category counts
            
            for document in snapshot.documents {
                if let bookISBN = document["bookISBN"] as? String {
                    db.collection("books").whereField("isbn", isEqualTo: bookISBN).getDocuments { bookSnapshot, bookError in
                        if let bookError = bookError {
                            print("Error fetching book documents: \(bookError)")
                            return
                        }
                        
                        guard let bookSnapshot = bookSnapshot else {
                            print("Book snapshot is nil")
                            return
                        }
                        
                        for bookDocument in bookSnapshot.documents {
                            if let selectedCategory = bookDocument["selectedCategory"] as? String {
                                // Increment count for each category
                                categoryCounts[selectedCategory, default: 0] += 1
                            }
                        }
                        
                        // Update UI on the main thread
                        DispatchQueue.main.async {
                            // Calculate total count of books
                            let totalCount = categoryCounts.values.reduce(0, +)
                            // Create MacroData array
                            let macroDataArray = categoryCounts.map { (name, count) in
                                // Calculate percentage
                                let percentage = Int((Double(count) / Double(totalCount)) * 100)
                                return MacroData(name: name, value: percentage)
                            }
                            // Sort macroDataArray by count to ensure continuity
                            self.macros = macroDataArray.sorted(by: { $0.value > $1.value })
                        }

                    }
                }
            }
        }
    }


    func fetchCheckinDetails() {
        let db = Firestore.firestore()
        
        db.collection(collectionName)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        let checkInDate = data["checkInDate"] as? String ?? ""
                        checkinDetails.append(CheckinDetails(id: document.documentID, checkInDate: checkInDate))
                    }
                    
                    processData()
                }
            }
    }
    
    func processData() {
        for detail in checkinDetails {
            // Assuming checkInDate is in the format dd/MM/yyyy
            let components = detail.checkInDate.split(separator: "/")
            let date = "\(components[2])-\(components[1])-\(components[0])" // Convert to yyyy-MM-dd for consistency
            
            if let count = dataPoints[date] {
                dataPoints[date] = count + 1
            } else {
                dataPoints[date] = 1
            }
        }
        
        maxValue = dataPoints.values.max() ?? 0
    }
    
    func fetchUsersCount() {
        let db = Firestore.firestore()
        
        db.collection(usersCollectionName)
            .whereField("userType", isEqualTo: "Member") 
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    self.usersCount = querySnapshot?.documents.count ?? 0
                }
            }
    }

    func fetchBookRatings() {
        let db = Firestore.firestore()
        
        db.collection(bookRatingCollectionName)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    for document in querySnapshot!.documents {
                        let isbn = document.documentID
                        let ratings = document.data()["ratings"] as? [Int] ?? []
                        ratingDetails.append(RatingDetails(id: document.documentID, isbn: isbn, ratings: ratings))
                    }
                    fetchCategoryForRatings()
                }
            }
    }
    
    func fetchCategoryForRatings() {
        let db = Firestore.firestore()
        
        for ratingDetail in ratingDetails {
            db.collection(booksCollectionName)
                .whereField("isbn", isEqualTo: ratingDetail.isbn) // Match field isbn with ratingDetail.isbn
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            let category = document.data()["selectedCategory"] as? String ?? ""
                            if let count = categoryRatings[category] {
                                categoryRatings[category] = count + ratingDetail.ratings.count
                            } else {
                                categoryRatings[category] = ratingDetail.ratings.count
                            }
                        }
                    }
                }
        }
    }
}

struct BarChartView: View {
    @State private var weeklyFine: Int = 0
    let dataPoints: [String: Int]
    let usersCount: Int
    let maxValue: Int

    var body: some View {
        VStack {
            HStack(){
                ZStack{
                    Rectangle()
                        .frame(width:130,height: 70)
                        .foregroundColor((Color(red: 228/255, green: 133/255, blue: 134/255)))
                        .cornerRadius(10.0)
                    Text("Users \n\(usersCount)")
                        .font(.title3).bold()
                        .multilineTextAlignment(.center)
                        .font(.title)
                }
                Spacer()
                ZStack{
                    Rectangle()
                        .frame(width:130,height: 70)
                        .foregroundColor((Color(red: 228/255, green: 133/255, blue: 134/255)))
                        .cornerRadius(10.0)
                    Text("Weekly Fine \n₹ \(weeklyFine)")
                        .font(.title3).bold()
                        .multilineTextAlignment(.center)
                        .font(.title)
                }
            }.padding(.horizontal)
            
            
        }
        .onAppear {
            fetchFines()
        }
        .padding()
        
    }
    private func fetchFines() {
            let today = Date()
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            let todayString = dateFormatter.string(from: today)
            let lastWeekString = dateFormatter.string(from: lastWeek)
            
            
            
            // Fetch fine details for last week
        // Fetch fine details for last week
        db.collection("FineDetails")
            .whereField("Date", isGreaterThanOrEqualTo: lastWeekString)
            .whereField("Date", isLessThanOrEqualTo: todayString)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching last week's fine: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for last week's fine")
                    return
                }
                print("Documents for last week's fine: \(documents)")
                var lastWeekFineTotal: Double = 0.0
                for document in documents {
                    let data = document.data()
                    if let fineAmountString = data["fineAmount"] as? String,
                       let fineAmount = Double(fineAmountString) {
                        lastWeekFineTotal += fineAmount
                    }
                }
                self.weeklyFine = Int(lastWeekFineTotal.rounded())
            }

        }
}

struct BarChartCell: View {
    let value: Int
    let maxValue: Int
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                        .frame(width: 20, height: max(geometry.size.height * CGFloat(value) / CGFloat(maxValue), 20))  // Ensuring a minimum bar height of 20
                    Spacer()
                }
            }
            .frame(minHeight: 200)  // Specify a minimum height for the GeometryReader
            Text("\(value)")
                .font(.caption)
        }

        .padding(.vertical, 5)
    }
}

struct CategoryChartView: View {
    let categoryRatings: [String: Int]
    let scaleFactor: CGFloat = 10.0
    var body: some View {
        VStack {
            VStack{
                HStack(alignment:.bottom){
                    ForEach(categoryRatings.sorted(by: { $0.key < $1.key }), id: \.key) { (category, ratingCount) in
                        VStack {
                            Text("\(ratingCount)")
                                .font(.caption)
                            ZStack{
                                
                                RoundedRectangle(cornerRadius:5)
                                    .fill(Color.pink)
                                    .frame(width: 40, height: CGFloat(ratingCount) * scaleFactor, alignment: .bottom)
                            }
                            Text(category)
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(height:240, alignment: .bottom)
                .padding(20)
                .background(.thinMaterial)
                .cornerRadius(6)
                .padding()
            }
        }
        .padding()
    }
}

struct LineChart: View {
    let dataPoints: [Double]
    let labels: [String]

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    // Background grid
                    Path { path in
                        let stepHeight = geometry.size.height / CGFloat(dataPoints.max() ?? 1)
                        for i in 1..<5 {
                            let y = stepHeight * CGFloat(i)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    
                    // Line
                    Path { path in
                        let stepWidth = geometry.size.width / CGFloat(dataPoints.count - 1)
                        for i in 0..<dataPoints.count {
                            let x = stepWidth * CGFloat(i)
                            let y = geometry.size.height - (geometry.size.height * CGFloat(dataPoints[i]) / CGFloat(dataPoints.max() ?? 1))
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Labels
                    VStack {
                        Spacer()
                        HStack {
                            ForEach(labels, id: \.self) { label in
                                Text(label)
                                    .font(.system(size: 17)) // Adjust the size as needed
                                    .bold()
                                    .foregroundColor(.gray)
                                    .frame(width: geometry.size.width / CGFloat(labels.count), alignment: .center)
                            }
                        }
                    }
                }
            }
        }
    }
}

// DateFormatter for converting Firestore date string to Date
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy"
    return formatter
}()


struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        Analytics()
    }
}
