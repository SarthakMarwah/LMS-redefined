//
//  AccountScreenAdmin.swift
//  LMS3
//
//  Created by Aditya Majumdar on 09/05/24.
//

import SwiftUI
import Firebase

struct AccountScreenAdmin: View {
    // Define primaryPink color constant
    let primaryPink = Color(red: 0.9882352941176471, green: 0.7294117647058823, blue: 0.6784313725490196)
    
    @State private var isDarkModeEnabled = false
    @State private var userName: String?
    @State private var isLoggedOut = false
    
    var body: some View {
        
                    ZStack {
                        Color(red: 242/255, green: 243/255, blue: 247/255)
                            .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Account")
                        .font(.custom("SF Pro", size: 24).weight(.bold))
                    
                        .foregroundColor(Color.black)
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(Color.white)
                            .frame(width: 340, height: 116)

                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.custom("SF Pro", size: 46).weight(.bold))
                                    .foregroundColor(.black)
                                    .offset(x:-20)
                                
                                
                                if let userName = userName {
                                    Text("\(userName)")
                                        .font(.custom("SF Pro", size: 18).weight(.bold))
                                        .foregroundColor(Color.black)
                                } else {
                                    Text("Loading...")
                                        .font(.custom("SF Pro", size: 18).weight(.bold))
                                        .foregroundColor(Color.black)
                                }
                            }
                            .offset(x:-60)
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.2))
                                .frame(width:200,height: 1)
                            
                            
                            NavigationLink(destination: ProfileAdmin()) {
                                Text("Profile")
                                    .font(.custom("SF Pro", size: 18))
                                    .foregroundColor(Color.black)
                                    .offset(x:30,y:-3)
                                
                                Spacer()
                                
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                    .offset(x:-30)
                            }
                            
                        }
                        .padding(15)
                        Spacer()
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(Color.white)
                            .frame(width: 340, height: 74)
                        HStack {
                            Text("Dark Mode")
                                .font(.custom("SF Pro", size: 18))
                                .foregroundColor(Color.black)
                                .padding(.leading, 45)
                            
                            Spacer()
                            
                            Toggle(isOn: $isDarkModeEnabled) {
                                Text("")
                            }
                            .padding(.trailing, 50)
                        }
                    }
                    
 
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(Color.white)
                            .frame(width: 340, height: 74)
                       
                            NavigationLink(destination:  CalendarAdmin()) {
                                HStack{
                                    Text("Calendar")
                                        .font(.custom("SF Pro", size: 20).weight(.bold))
                                        .foregroundColor(Color.black)
                                        .padding(.leading, 45)
                                    
                                    Spacer()
                                    
                                    
                
                                    Image(systemName: "chevron.right")
                                        .font(.custom("SF Pro", size: 18))
                                        .foregroundColor(.black)
                                }
                                
                            }
                        .padding(.trailing, 45)
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(Color.white)
                            .frame(width: 340, height: 74)
                       
                            NavigationLink(destination:   BroadcastNotificationView()) {
                                HStack{
                                    Text("Broadcast")
                                        .font(.custom("SF Pro", size: 20).weight(.bold))
                                        .foregroundColor(Color.black)
                                        .padding(.leading, 45)
                                    
                                    Spacer()
                                    
                                    
                
                                    Image(systemName: "chevron.right")
                                        .font(.custom("SF Pro", size: 18))
                                        .foregroundColor(.black)
                                }
                                
                            }
                        .padding(.trailing, 45)
                    }
                    Button(action: signOut) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color.white)
                                .frame(width: 340, height: 74)
                            HStack {
                                Text("Sign Out")
                                    .font(.custom("SF Pro", size: 20))
                                    .foregroundColor(Color.black)
                                    .padding(.leading, 45)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                
                            }
                            .padding(.trailing, 45)
                        }
                    }
                    Spacer()
                    
                    
                }
                .padding(.top, 30)
            }
        .onAppear {
            fetchUserData { name in
                self.userName = name
            }
        }
        .background(
                    NavigationLink(
                        destination: LoginView().navigationBarBackButtonHidden(),
                        isActive: $isLoggedOut,
                        label: { EmptyView() }
                    )
                )
    }
    
    func fetchUserData(completion: @escaping (String?) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userRef = db.collection("Users").document(uid)

            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let name = document.data()?["name"] as? String {
                        completion(name)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Handle successful sign-out, such as navigating to a login screen
            isLoggedOut = true
        } catch let signOutError as NSError {
            // Handle sign-out error
            print("Error signing out: \(signOutError)")
        }
    }
}

struct AccountScreenLibPreviews: PreviewProvider {
    static var previews: some View {
       AccountScreenAdmin()
    }
}

