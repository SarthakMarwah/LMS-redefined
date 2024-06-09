//
//  BroadcastNotification.swift
//  LMS3
//
//  Created by Aditya Majumdar on 05/05/24.
//

import SwiftUI

struct BroadcastNotificationView: View {
    @State private var notificationTitle = ""
    @State private var notificationMessage = ""
    @State private var selectedDate = Date()
    let notify = NotificationHandler()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Broadcast Notification")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("Pink"))
                .offset(y:25)

            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Notification Title")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .foregroundColor(Color("Pink"))
                TextField("Enter Title", text: $notificationTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            
            VStack(alignment: .leading) {
                Text("Notification Message")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .foregroundColor(Color("Pink"))
                    .offset(x:-15)
                TextEditor(text: $notificationMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(width:330,height:100)
                    .padding(.bottom)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)) // Add border

            }
            
            DatePicker("Pick a date: ", selection: $selectedDate, in: Date()...)
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                .foregroundColor(Color("Pink"))
            
            Button(action: {
                sendNotification()
            }) {
                Text("Push Notification")
                    .fontWeight(.bold)
                    .padding()
                    .frame(height: 45)
                    .foregroundColor(.white)
                    .background(Color(red: 228/255, green: 133/255, blue: 134/255))
                    .cornerRadius(10)
                    .offset(y:-25)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            notify.askPermission()
        }
    }
    
    private func sendNotification() {
        notify.sendNotification(
            date: selectedDate,
            type: "date",
            title: notificationTitle,
            body: notificationMessage
        )
    }
}

struct BroadcastNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        BroadcastNotificationView()
    }
}
