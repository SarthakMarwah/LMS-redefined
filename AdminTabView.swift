//
//  AdminTabView.swift
//  LMS3
//
//  Created by Aditya Majumdar on 29/04/24.
//

import SwiftUI


struct AdminTabView: View {
    @State private var isLoggedOut = false
    var body: some View {
      
            TabView{
                Group{
                    
                         AdminHomeView()
                        .tabItem {  Label("Home", systemImage: "book") }

                    
                        shiftView()
                        .tabItem {  Label("Shift", systemImage: "calendar.badge.plus") }
                    
                    FinesManagementView()
                        .tabItem {  Label("Fine", systemImage: "dollarsign.square") }
                    Analytics()
                        .tabItem {  Label("Analytics", systemImage: "chart.bar.xaxis") }
                    
//                    CalendarAdmin()
//                        .tabItem {  Label("Calendar", systemImage: "calendar") }
                    
                    BroadcastNotificationView()
                        .tabItem {  Label("Broadcast", systemImage: "speaker") }
                }
               
               
            }.accentColor(Color(red: 228/255, green: 133/255, blue: 134/255))
        }
    
}



#Preview {
    AdminTabView()
}
