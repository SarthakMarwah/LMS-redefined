//
//  LoginView.swift
//  LMS3
//
//  Created by Aditya Majumdar on 20/04/24.
//

import SwiftUI
import FirebaseAuth
import Firebase

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedUserType: UserType = .admin

    @State private var isLoggedIn: Bool = false
    @State private var loginError: String?
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Image("BookWise Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .padding(.top, 60)

                Text("Welcome Back!")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 20)
                    .padding(.bottom, 50)

                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .autocapitalization(.none)

                    Picker("Select User Type", selection: $selectedUserType) {
                        Text("Admin").tag(UserType.admin)
                        Text("Librarian").tag(UserType.librarian)
                        Text("Member").tag(UserType.member)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    Button("Log In") {
                        loginUser()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 228/255, green: 133/255, blue: 134/255))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
                    
                    NavigationLink(
                        destination: destinationView(),
                        isActive: $isLoggedIn,
                        label: { EmptyView() }
                    )
                    .hidden()
                    
                    HStack {
                        
                        Spacer()
                        Button("Forgot Password?") {
                            resetPassword()
                        }
                        .foregroundColor(.blue)
                        .padding(.top, 0)
                        .padding(.bottom, 15)
                        .padding(.trailing,10)
                    }
                    HStack{

                        NavigationLink(
                            destination: SignupView().navigationBarBackButtonHidden(),
                            label: {
                                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(.black)
                                    Text("Sign Up")
                                        .foregroundColor(.blue)
                                }
                            }
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(loginError ?? "An error occurred."), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    private func resetPassword() {
         guard !email.isEmpty else {
             loginError = "Please enter your email to reset password."
             showAlert = true
             return
         }

         Auth.auth().sendPasswordReset(withEmail: email) { error in
             if let error = error {
                 loginError = "Failed to reset password: \(error.localizedDescription)"
                 showAlert = true
             } else {
                 showAlert = true
                 loginError = "Password reset instructions sent to your email."
             }
         }
     }
 

    private func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            loginError = "Please enter email and password."
            showAlert = true
            return
        }


        Auth.auth().signIn(withEmail: email, password: password) { [self] (result, error) in
            if let error = error {
                loginError = error.localizedDescription
                showAlert = true
            } else if let authResult = result {
                
                let userRef = Firestore.firestore().collection("Users").document(authResult.user.uid)
                userRef.getDocument { document, error in
                    if let error = error {
                        loginError = "Failed to fetch user data: \(error.localizedDescription)"
                        showAlert = true
                    } else if let userData = document?.data(),
                              let userTypeString = userData["userType"] as? String,
                              let userType = UserType(rawValue: userTypeString) {
                        
                        if userType == selectedUserType {
                            isLoggedIn = true 
                        } else {
                            loginError = "Invalid user type for login."
                            showAlert = true
                        }
                    } else {
                        loginError = "User not found or invalid data."
                        showAlert = true
                    }
                }
            }
        }
    }
    private func destinationView() -> some View {
        switch selectedUserType {
        case .admin:
            return AnyView(AdminTabView().navigationBarBackButtonHidden())
        case .librarian:
            return AnyView(librarianTabView().navigationBarBackButtonHidden())
        case .member:
            return AnyView(memberTabView().navigationBarBackButtonHidden())
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
