//
//  AddCategory.swift
//  LMS3
//
//  Created by Aditya Majumdar on 22/04/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import Combine

struct AdminHomeView: View {
    @State private var isAddingCategory = false
    @State private var categoryName = ""
    @State private var selectedImage: UIImage?
    @State private var categories: [Category] = []
    @State private var isEditingCategory = false
    @State private var selectedCategory: Category?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isAccountScreenPresented = false
    
    
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    var body: some View {
            VStack {
                HStack {
                    Text("Welcome")
                        .font(.largeTitle).bold()
                        .padding()
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.custom("SF Pro", size: 44))
                        .padding(.trailing,10)
                        .onTapGesture {
                            isAccountScreenPresented = true
                        }
                }
                HStack {
                    Text("Edit Categories")
                        .font(.title2).bold()
                    Spacer()
                    Button(action: {
                        isAddingCategory = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color("Pink"))
                    }
                    .padding()
                    .sheet(isPresented: $isAddingCategory) {
                        AddCategoryView(
                            isPresented: $isAddingCategory,
                            categoryName: $categoryName,
                            selectedImage: $selectedImage,
                            saveCategory: saveCategory
                        )
                    }
                }
                .padding(.horizontal)
                
                List {
                    ForEach(categories) { category in
                        NavigationLink(destination: EditCategoryDetailView(categoryName: $categoryName,category: category) { newName, newImage in
                            updateCategory(category, newName: newName, newImage: newImage)
                        }) {
                            CategoryRowView(category: category, editAction: {
                                editCategory(category)
                            })
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let categoryName = categories[index].name
                            deleteCategory(byName: categoryName)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(
                            NavigationLink(
                                destination: AccountScreenLib(),
                                isActive: $isAccountScreenPresented
                            ) {
                                EmptyView()
                            }
                        )
            .onAppear {
                fetchCategories()
            }
            .alert(isPresented: $showAlert) {
                            Alert(title: Text(alertMessage))
                        }
                    }
                
    
    private func editCategory(_ category: Category) {
        selectedCategory = category
        isEditingCategory = true
    }
    
    private func updateCategory(_ category: Category, newName: String, newImage: UIImage?) {
        // Find the document ID of the category
        db.collection("categories")
            .whereField("id", isEqualTo: category.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                for document in documents {
                    let categoryID = document.documentID
                    var updateData: [String: Any] = ["name": newName]
                    
                    if let newImage = newImage {
                        // Upload new image to storage
                        uploadImage(newImage, forCategory: category) { imageUrl in
                            // Update imageUrl in Firestore
                            updateData["imageUrl"] = imageUrl
                            
                            // Update category data in Firestore
                            self.updateCategoryData(for: categoryID, with: updateData, newName: newName)
                        }
                    } else {
                        // Update category data in Firestore
                        self.updateCategoryData(for: categoryID, with: updateData, newName: newName)
                        
                    }
                }
            }
    }
    
    private func updateCategoryData(for categoryID: String, with updateData: [String: Any], newName: String) {
        // Update category data in Firestore
        self.db.collection("categories").document(categoryID).updateData(updateData) { error in
            if let error = error {
                print("Error updating category: \(error.localizedDescription)")
            } else {
                if let index = self.categories.firstIndex(where: { $0.id == categoryID }) {
                    self.categories[index].name = newName
                    // Optionally, update imageUrl here if needed
                    showAlert = true
                                        alertMessage = "Successfully Updated Category"
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage, forCategory category: Category, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Error converting image to data.")
            return
        }
        
        let imageRef = storage.child("category_images/\(UUID().uuidString).jpg")
        
        _ = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                if let downloadURL = url {
                    completion(downloadURL.absoluteString)
                } else {
                    print("Download URL is nil.")
                }
            }
        }
    }
    
    
    private func saveCategory(imageUrl: String) {
        let newCategory = Category(name: categoryName, imageUrl: imageUrl)
        
        do {
            _ = try db.collection("categories").addDocument(from: newCategory)
            categoryName = ""
                        selectedImage = nil
                        isAddingCategory = false
                        showAlert = true
                        alertMessage = "Successfully Added Category"
        } catch let error {
            print("Error adding category: \(error.localizedDescription)")
        }
    }
    
    private func fetchCategories() {
        db.collection("categories").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching categories: \(error?.localizedDescription ?? "")")
                return
            }
            
            categories = documents.compactMap { queryDocumentSnapshot -> Category? in
                try? queryDocumentSnapshot.data(as: Category.self)
            }
        }
    }
    
    private func deleteCategory(byName categoryName: String) {
        db.collection("categories")
            .whereField("name", isEqualTo: categoryName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                for document in documents {
                    let categoryID = document.documentID
                    self.db.collection("categories").document(categoryID).delete { error in
                        if let error = error {
                            print("Error deleting category: \(error.localizedDescription)")
                        } else {
                            if let index = self.categories.firstIndex(where: { $0.id == categoryID }) {
                                self.categories.remove(at: index)
                            }
                        }
                    }
                }
            }
    }
    
}

struct EditCategoryDetailView: View {
    @Binding var categoryName: String
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var showAlert = false
        @State private var alertMessage = ""
    
    let category: Category
    let onSave: (String, UIImage?) -> Void
    
    var body: some View {
        VStack(alignment:.leading) {
            Text("Edit Categories")
                .font(.largeTitle).bold()
                .padding(.bottom, 30)
            
            Text("Category name")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)
                .padding(.leading)
            TextField("Category Name", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading)
                .padding(.bottom)
                .padding(.trailing)
            
            Text("Category Image")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)
                .padding(.leading)
            
            if let imageUrl = URL(string: category.imageUrl) {
                AsyncImage(url: imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .padding(.leading)
                    .padding(.trailing)
            }
            
            Button(action: {
                isShowingImagePicker = true
            }) {
                Text("Select Image")
                    .foregroundColor(Color("Pink"))
            }
            .padding()
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            
            Button(action: {
                onSave(categoryName, selectedImage)
            }) {
                Text("Save")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(Color("Pink"))
                    .cornerRadius(10)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                            Alert(title: Text(alertMessage))
                        }
                    }
        .padding()
        .onAppear {
            categoryName = category.name
        }
        Spacer()
    }
}

struct CategoryRowView: View {
    let category: Category
    var editAction: () -> Void
    
    var body: some View {
        HStack {
            if let imageUrl = URL(string: category.imageUrl) {
                AsyncImage(url: imageUrl)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.trailing)

            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.trailing)
            }
            Text(category.name)
                .font(.headline)
            Spacer()
        }
        .frame(height: 75)
        .cornerRadius(15)
    }
}

struct AddCategoryView: View {
    @Binding var isPresented: Bool
    @Binding var categoryName: String
    @Binding var selectedImage: UIImage?
    @State private var showAlert = false
        @State private var alertMessage = ""
    
    @State private var isShowingImagePicker = false
    
    var saveCategory: (String) -> Void
    
    private let storage = Storage.storage().reference()

    var body: some View {
        NavigationView {
            VStack {
                TextField("Category name", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .padding()
                }
                
                Button(action: {
                    self.isShowingImagePicker = true
                }) {
                    Text("Select Image")
                        .foregroundColor(Color("Pink"))
                }
                .padding()
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(selectedImage: $selectedImage)
                }
                
                Spacer()
                
                Button(action: {
                    if let selectedImage = selectedImage {
                        uploadImage(selectedImage)
                    } else {
                        saveCategory("")
                    }
                }) {
                    Text("Save")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color("Pink"))
                        .cornerRadius(10)
                }
                .alert(isPresented: $showAlert) {
                                    Alert(title: Text(alertMessage))
                                }
                .padding()
            }
            .navigationTitle("Add Category")
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Error converting image to data.")
            return
        }
        
        let imageRef = storage.child("category_images/\(UUID().uuidString).jpg")
        
        _ = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                if let downloadURL = url {
                    saveCategory(downloadURL.absoluteString)
                } else {
                    print("Download URL is nil.")
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
}

struct AsyncImage: View {
    @ObservedObject private var imageLoader: ImageLoader
    private let placeholderImage: Image
    
    init(url: URL, placeholder: Image = Image(systemName: "photo")) {
        _imageLoader = ObservedObject(wrappedValue: ImageLoader(url: url))
        placeholderImage = placeholder
    }
    
    var body: some View {
        if let image = imageLoader.image {
            Image(uiImage: image)
                .resizable()
        } else {
            placeholderImage
                .resizable()
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    
    init(url: URL) {
        self.url = url
        loadImage()
    }
    
    private func loadImage() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}

struct Category: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var imageUrl: String
}

struct AdminHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AdminHomeView()
    }
}
