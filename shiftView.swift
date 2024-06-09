//
//  Librarian.swift
//  LMS3
//
//  Created by Aditya Majumdar on 29/04/24.
//

import SwiftUI
import Firebase

struct Librarian: Identifiable {
    let id: String // ID from Firebase
    let name: String
}

struct shiftView: View {
    @State private var search: String = ""
    @State private var selectedLibrarian: Librarian?
    @State private var librarians: [Librarian] = [] // Array to hold librarian data
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    HStack{
                        Text("Manage Shifts")
                            .font(.largeTitle).bold()
                            .padding()
                            .padding(.bottom)
                            .offset(y:7)
                    Spacer()
                        NavigationLink(destination: CalendarAdmin()){
                                Image(systemName: "calendar")
                                    .font(.title)
                                    .padding()
                                    
                            }
                    }
                    ZStack {
                        Rectangle()
                            .cornerRadius(10.0)
                            .foregroundColor(.gray)
                            .opacity(0.3)
                            .frame(width: 360, height: 40)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                            TextField("Search Library", text: $search)
                                .frame(width: 290)
                            
                        }
                    }.padding(.bottom, 20)
                        .offset(x:16)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            ForEach(librarians) { librarian in
                                LibrarianView(librarian: librarian, selectedLibrarian: $selectedLibrarian)
                            }
                        }
                    }
                }
            }
            
            
           
            
        }
        .onAppear(perform: fetchLibrarians) // Fetch librarian data when the view appears
        
        
          
    }
    
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        let userType = "Librarian"
        
        db.collection("Users")
            .whereField("userType", isEqualTo: userType)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching librarians: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                // Parse documents and populate librarians array
                self.librarians = documents.compactMap { document in
                    guard let id = document.data()["id"] as? String, // Get the document ID
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    
                    return Librarian(id: id, name: name)
                }
            }
    }
}

struct LibrarianView: View {
    let librarian: Librarian
    @Binding var selectedLibrarian: Librarian?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color.gray.opacity(0.08))
                .frame(width:360,height: 120)
            
            HStack(spacing: 20) {
                Image(systemName: "person.circle.fill") // Assuming the image name is "librarian1" for all librarians
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8.0)
                VStack {
                    Text(librarian.name)
                        .font(.headline)
                        .frame(width: 180, alignment: .topLeading)
                    
                    NavigationLink(destination: schedulePage(librarian: librarian)) {
                        VStack {
                            Text("Schedule")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .frame(width: 100, height: 30)
                        .background(Color(red: 228/255, green: 133/255, blue: 134/255))
                        .cornerRadius(8)
                    }
                    .padding(.leading, 30)
                }
            }
        }
        .padding(.leading,10)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
        .offset(x:-5)// Expand the width to fill available space
    }
}


struct shiftView_Previews: PreviewProvider {
    static var previews: some View {
        shiftView()
    }
}
