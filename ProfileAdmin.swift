//
//  ProfileAdmin.swift
//  LMS3
//
//  Created by Aditya Majumdar on 09/05/24.
//

import SwiftUI

import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import Combine
import Foundation



struct ProfileAdmin: View {
    
    // Define primaryPink color constant
    let primaryPink = Color(red: 0.9882352941176471, green: 0.7294117647058823, blue: 0.6784313725490196)
    
    // UID to fetch user details
    let uid: String = "user_uid_here" // Replace with actual UID
    
    // User details fetched from Firestore
    @State private var name: String?
    @State private var email: String?
    @State private var userType: String?
    @State private var isLoading = false
    
//    private var dobFormatted: String {
//        if let dob = dob {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "dd/MM/yyyy"
//            return formatter.string(from: dob)
//        } else {
//            return "N/A"
//        }
//    }
    
    var body: some View {
        // Profile
        ZStack {
            Color(red: 242/255, green: 243/255, blue: 247/255)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Profile")
                    .font(.custom("SF Pro", size: 24) .weight(.bold))
                    .foregroundColor(Color.black)
                    .offset(y: -10)
                
                if isLoading {
                    ProgressView()
                } else {
                    if let name = name, let email = email, let userType = userType {
                        VStack{
                            Image(systemName: "person.circle.fill")
                                .font(.custom("SF Pro", size: 74))
                                .foregroundColor(.black)
                            
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color.white)
                                .frame(width: 340, height: 210)
                                .overlay(
                                    VStack(spacing: 20) {
                                        ProfileField(title: "Name", value: name, isLastField: false)
                                        Divider()
                                        ProfileField(title: "Email", value: email, isLastField: false)
                                        Divider()
                                        ProfileField(title: "User Type", value: userType, isLastField: true)
                                        
                                    }
                                    
                                    
                                )
                           
                        }
                    } else {
                        Text("User details not found.")
                            .foregroundColor(.black)
                            .font(.custom("SF Pro", size: 18))

                    }
                }
                
                Spacer() // Pushes the content to the top
            }
            .padding(.top, 30) // Adds padding to the top of VStack
            .onAppear {
                fetchUserDetails()
            }
        }
    }
    
    // Function to fetch user details from Firestore
    private func fetchUserDetails() {
        isLoading = true
        fetchUserData { userData in
            if let userData = userData {
                self.name = userData.name
                self.email = userData.email
                self.userType = userData.userType
                self.isLoading = false
            } else {
                print("User details not found.")
                self.isLoading = false
            }
        }
    }
    
    // Struct to hold user data
    struct UserData {
        let name: String
        let email: String
        let userType: String
    }
}

struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAdmin()
    }
}


