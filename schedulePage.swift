//
//  schedulePage.swift
//  LMS3
//
//  Created by Aditya Majumdar on 29/04/24.
//

import SwiftUI
import EventKit
import Firebase
import SwiftUI

struct SlotPicker: View {
    @Binding var selectedHour: Int
    
    var body: some View {
        Picker("", selection: $selectedHour) {
            ForEach(0..<8, id: \.self) { index in
                let hour = index * 3 + 9 // Calculate the hour based on the index (0 to 7)
                let displayHour = hour % 12 == 0 ? 12 : hour % 12 // Convert 24-hour format to 12-hour format
                let displayAMPM = hour < 12 ? "AM" : "PM" // Determine AM or PM
                
                Text("\(displayHour):00 \(displayAMPM)") // Display in 12-hour format with AM/PM
                    .tag(hour)
            }
        }
        .frame(width: 120, height: 35)
        .pickerStyle(MenuPickerStyle())
    }
}

struct schedulePage: View {
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var repeatOption: RepeatOption = .never
    @State private var showAlert = false
    @State private var eventTitle: String = ""
    @State private var selectedHour = 0 // Default to 9:00 AM
    var db = Firestore.firestore()
    let eventStore = EKEventStore()
    
    enum RepeatOption: String, CaseIterable, Identifiable {
        case never = "Never"
        case everyday = "Everyday"
        case everyWeek = "Every Week"
        case everyMonth = "Every Month"
        
        var id: String { self.rawValue }
    }
    
    let librarian: Librarian
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .cornerRadius(10.0)
                    .foregroundColor(.gray)
                    .opacity(0.16)
                    .frame(width: 360, height: 150)
                    .shadow(radius: 10)
                
                HStack(spacing: 20) {
                    //img
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(2.0)
                    
                    Text(librarian.name)
                        .font(.headline)
                        .frame(width: 180, alignment: .topLeading)
                        .foregroundColor(Color("Pink"))
                }
            }
            Spacer()
            
            HStack {
                Text("Date")
                    .bold()
                    .padding(10)
                Spacer()
                
                DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .cornerRadius(10)
                    .padding()
            }
            .background(Color(red: 235/255, green: 235/255, blue: 240/255))
            .cornerRadius(15)
            .padding(.horizontal)
            .cornerRadius(15)
            .padding(.horizontal)
            .onAppear {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date()) // Get the start of the current day
                startDate = today // Set the start date to today
            }
            .onChange(of: startDate) { newStartDate in
                // Ensure that the start date cannot be before today
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                if newStartDate < today {
                    startDate = today
                }
            }
            
            HStack {
                Text("Time Slot")
                    .bold()
                    .padding(10)
                Spacer()
                
                SlotPicker(selectedHour: $selectedHour)
                    .frame(width: 120)
                    .cornerRadius(10)
                    .padding()
                    .labelsHidden()
                    .onChange(of: selectedHour) { hour in
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: startDate)
                        let newStartDate = calendar.date(from: components)?.addingTimeInterval(TimeInterval(hour * 3600))
                        if let newStartDate = newStartDate {
                            startDate = newStartDate
                        }
                    }
                    .onChange(of: startDate) { _ in
                        endDate = Calendar.current.date(byAdding: .hour, value: 3, to: startDate) ?? Date()
                    }
            }
            .background(Color(red: 235/255, green: 235/255, blue: 240/255))
            .cornerRadius(15)
            .padding(.horizontal)
            .cornerRadius(15)
            .padding(.horizontal)
            
            HStack {
                Text("Repeat")
                    .bold()
                    .padding(10)
                Spacer()
                
                Picker("Repeat", selection: $repeatOption) {
                    ForEach(RepeatOption.allCases) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            }
            .background(Color(red: 235/255, green: 235/255, blue: 240/255))
            .cornerRadius(15)
            .padding(.horizontal)
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                eventTitle = librarian.name
                addEventToCalendar()
                scheduleEvent()
                showAlert = true
            }) {
                ZStack {
                    Rectangle()
                        .foregroundColor(Color(red: 228/255, green: 133/255, blue: 134/255))
                        .cornerRadius(15)
                        .frame(width: 300, height: 50)
                    Text("Schedule")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding()
                
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
                    Alert(title: Text("Success"), message: Text("Successfully scheduled."), dismissButton: .default(Text("OK")))
                }
    }
    
    func scheduleEvent() {
        // Create date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm" // Adjust the format as needed
        
        // Convert dates to string with desired format
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // Create a dictionary with event details
        let eventData: [String: Any] = [
            "name": librarian.name,
            "id": librarian.id,
            "startDate": startDateString,
            "endDate": endDateString,
            "repeatSelection": repeatOption.rawValue
        ]

        // Add a new document with a generated ID
        db.collection("Slots").addDocument(data: eventData) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added")
            }
        }
    }

    func addEventToCalendar() {
        let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        switch authorizationStatus {
        case .authorized:
            saveEvent()
        case .notDetermined:
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    saveEvent()
                } else {
                    print("Permission denied by the user.")
                }
            }
        case .denied, .restricted:
            print("Permission not granted to access calendar.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }

    func saveEvent() {
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = eventTitle
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        
        switch repeatOption {
        case .never:
            newEvent.recurrenceRules = nil
        case .everyday:
            let recurrenceRule = EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
            newEvent.recurrenceRules = [recurrenceRule]
        case .everyWeek:
            let recurrenceRule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
            newEvent.recurrenceRules = [recurrenceRule]
        case .everyMonth:
            let recurrenceRule = EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
            newEvent.recurrenceRules = [recurrenceRule]
        }
        
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            print("Event saved successfully.")
        } catch {
            print("Error saving event: \(error.localizedDescription)")
        }
    }
}

//struct schedulePage_Previews: PreviewProvider {
//    static var previews: some View {
//        let librarian = Librarian(name: "John Doe") // Assuming Librarian struct or class exists with a 'name' property
//
//        return schedulePage(librarian: librarian)
//    }
//}

