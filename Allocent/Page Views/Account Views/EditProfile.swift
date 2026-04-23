//
//  EditProfile.swift
//  BudgetApp
//
//  Created by Valerie on 2/25/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct EditProfile: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionViewModel
    
    @State private var displayFirstName: String = ""
    @State private var displayLastName: String = ""
    @State private var displayEmail: String = ""
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let userService = UserService()
    
    private var currentUser: AppUser? {
        switch session.state {
        case .active(let user), .onboarding(let user):
            return user
        default:
            return nil
        }
    }
    
    private var hasChanges: Bool {
        guard let user = currentUser else { return false }
        return displayFirstName != user.firstName
            || displayLastName != user.lastName
            || displayEmail != user.email
            || selectedImageData != nil
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea(edges: .all)
            VStack {
                HeaderWithBack(pageName: "Edit Profile")
                VStack(spacing: 30) {
                    
                    // Profile Photo Section
                    VStack {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let imageData = selectedImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 112, height: 112)
                                        .clipShape(Circle())
                                } else if let urlString = currentUser?.profileImageURL,
                                          let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 112, height: 112)
                                                .clipShape(Circle())
                                        default:
                                            profilePlaceholder
                                        }
                                    }
                                } else {
                                    profilePlaceholder
                                }
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color("OliveGreen"))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .offset(x: 4, y: 4)
                            }
                        }
                        
                        PhotosPicker("Change Photo", selection: $selectedPhoto, matching: .images)
                            .font(.subheadline)
                            .foregroundStyle(Color("OliveGreen"))
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        FormField(label: "First Name", text: $displayFirstName)
                        FormField(label: "Last Name", text: $displayLastName)
                        FormField(label: "Email", text: $displayEmail, keyboardType: .emailAddress)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(.rect(cornerRadius: 16))
                        }
                        
                        Button(action: {
                            Task { await saveChanges() }
                        }) {
                            Group {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Changes")
                                }
                            }
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(hasChanges ? Color("OliveGreen") : Color.gray)
                            .clipShape(.rect(cornerRadius: 16))
                        }
                        .disabled(!hasChanges || isSaving)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                Spacer()
                
            }
        }
        .onAppear {
            displayFirstName = currentUser?.firstName ?? ""
            displayLastName = currentUser?.lastName ?? ""
            displayEmail = currentUser?.email ?? ""
        }
        .onChange(of: selectedPhoto) {
            Task {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
        .alert("Error", isPresented: $showError) { } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color("OliveGreen").opacity(0.3))
            .frame(width: 112, height: 112)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 36))
                    .foregroundStyle(Color("OliveGreen"))
            }
    }
    
    private func saveChanges() async {
        guard let user = currentUser else { return }
        isSaving = true
        defer { isSaving = false }
        
        do {
            var imageURL: String?
            
            // Upload new profile image if selected
            if let imageData = selectedImageData {
                // Compress to JPEG
                let compressed = UIImage(data: imageData)?
                    .jpegData(compressionQuality: 0.7) ?? imageData
                imageURL = try await userService.uploadProfileImage(
                    uid: user.id,
                    imageData: compressed
                )
            }
            
            // Update Firestore profile
            try await userService.updateProfile(
                uid: user.id,
                firstName: displayFirstName,
                lastName: displayLastName,
                email: displayEmail,
                phoneNumber: user.phoneNumber,
                bio: user.bio,
                profileImageURL: imageURL
            )
            
            // Update email in Firebase Auth if changed
            if displayEmail != user.email {
                try await Auth.auth().currentUser?.sendEmailVerification(
                    beforeUpdatingEmail: displayEmail
                )
            }
            
            // Refresh session state with updated user data
            await session.refreshUser()
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
        
struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 16))
        }
    }
}


#Preview {
    EditProfile()
        .environmentObject(SessionViewModel())
}
