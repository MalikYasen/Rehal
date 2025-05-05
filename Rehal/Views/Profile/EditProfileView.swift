import SwiftUI
import Supabase

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var fullName: String = ""
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSuccessToast = false
    
    // State to track if form was changed
    @State private var formChanged = false
    @State private var showingDiscardAlert = false
    
    // Define the custom purple color (same as login page)
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile image section
                VStack {
                    // Profile image
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(logoPurple, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(logoPurple.opacity(0.7))
                            .frame(width: 120, height: 120)
                    }
                    
                    // Change photo button
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text("Change Photo")
                            .font(.subheadline)
                            .foregroundColor(logoPurple)
                    }
                    .padding(.top, 8)
                }
                .padding(.top, 20)
                
                // Form fields
                VStack(spacing: 16) {
                    // Full name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter your name", text: $fullName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onChange(of: fullName) { _ in
                                formChanged = true
                            }
                    }
                    
                    // Email field (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(authViewModel.email)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .foregroundColor(.gray)
                    }
                    
                    // Error message if any
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    // Save button
                    Button(action: {
                        saveProfile()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(logoPurple)
                                .cornerRadius(10)
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(formChanged ? logoPurple : logoPurple.opacity(0.6))
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isLoading || !formChanged)
                    .padding(.top, 16)
                    
                    // Change password button
                    NavigationLink(destination: ChangePasswordView()) {
                        Text("Change Password")
                            .fontWeight(.semibold)
                            .foregroundColor(logoPurple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(logoPurple, lineWidth: 1)
                            )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitle("Edit Profile", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                if formChanged {
                    showingDiscardAlert = true
                } else {
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(logoPurple)
            }
        )
        .onAppear {
            // Initialize form with current values
            fullName = authViewModel.displayName
        }
        .sheet(isPresented: $showingImagePicker) {
            // Use ProfileImagePicker instead of ImagePicker to avoid naming conflicts
            ProfileImagePicker(image: $profileImage)
                .onChange(of: profileImage) { _ in
                    formChanged = true
                }
        }
        .alert(isPresented: $showingDiscardAlert) {
            Alert(
                title: Text("Discard Changes?"),
                message: Text("You have unsaved changes. Are you sure you want to go back?"),
                primaryButton: .destructive(Text("Discard")) {
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            // Success toast
            VStack {
                Spacer()
                
                if showingSuccessToast {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile updated successfully!")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showingSuccessToast)
                }
            }
        )
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = authViewModel.session?.user.id else {
                    throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                // First, update the profile in Supabase
                try await updateProfileInSupabase(userId: userId)
                
                // Then update profile image if changed
                if let image = profileImage {
                    try await uploadProfileImage(userId: userId, image: image)
                }
                
                await MainActor.run {
                    isLoading = false
                    formChanged = false
                    showingSuccessToast = true
                    
                    // Hide the toast after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingSuccessToast = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateProfileInSupabase(userId: UUID) async throws {
        // Update the user's profile in the profiles table
        try await authViewModel.supabase.from("profiles")
            .update([
                "full_name": fullName
            ])
            .eq("id", value: userId.uuidString)
            .execute()
        
        // Also update the user metadata in Auth
        let userMetadata = ["full_name": AnyJSON.string(fullName)]
        // Use update(user:) method instead of updateUser
        try await authViewModel.supabase.auth.update(user: UserAttributes(data: userMetadata))
    }
    
    private func uploadProfileImage(userId: UUID, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let fileName = "\(userId.uuidString).jpg"
        let bucket = "profile-images"
        
        // Create file options
        let fileOptions = FileOptions(
            cacheControl: "3600",
            contentType: "image/jpeg"
        )
        
        // Upload the image - with or without path: label depending on your SDK version
        try await authViewModel.supabase.storage
            .from(bucket)
            .upload(
                fileName,  // Use path: label
                data: imageData,
                options: fileOptions
            )
        
        // Get the public URL - WITH path: label
        let publicURLResponse = try authViewModel.supabase.storage
            .from(bucket)
            .getPublicURL(path: fileName)  // Use path: label
        
        // Update the avatar_url in the profiles table
        try await authViewModel.supabase.from("profiles")
            .update([
                "avatar_url": publicURLResponse.absoluteString
            ])
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // Image Picker for selecting profile photos - renamed to avoid conflicts
    struct ProfileImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        @Environment(\.presentationMode) var presentationMode
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ProfileImagePicker
            
            init(_ parent: ProfileImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.image = image
                }
                
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // Change Password View
    
    struct ChangePasswordView: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject var authViewModel: AuthViewModel
        @State private var currentPassword = ""
        @State private var newPassword = ""
        @State private var confirmPassword = ""
        @State private var isLoading = false
        @State private var errorMessage: String?
        @State private var showingSuccessAlert = false
        
        // Define the custom purple color
        let logoPurple = Color(
            red: 121 / 255.0,
            green: 65 / 255.0,
            blue: 234 / 255.0,
            opacity: 1.0
        )
        
        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    // Lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(logoPurple)
                        .padding(.top, 40)
                    
                    Text("Change Your Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        // Current password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter current password", text: $currentPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // New password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter new password", text: $newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Confirm new password", text: $confirmPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // Password requirements
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password Requirements:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• At least 8 characters")
                                .font(.caption)
                                .foregroundColor(newPassword.count >= 8 ? .green : .gray)
                            
                            Text("• At least one uppercase letter")
                                .font(.caption)
                                .foregroundColor(newPassword.contains(where: { $0.isUppercase }) ? .green : .gray)
                            
                            Text("• At least one number")
                                .font(.caption)
                                .foregroundColor(newPassword.contains(where: { $0.isNumber }) ? .green : .gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        // Error message if any
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        // Update button
                        Button(action: {
                            updatePassword()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(logoPurple)
                                    .cornerRadius(10)
                            } else {
                                Text("Update Password")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? logoPurple : logoPurple.opacity(0.6))
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isLoading || !isFormValid)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitle("Change Password", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(logoPurple)
                }
            )
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Your password has been updated successfully."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
        
        private var isFormValid: Bool {
            // Check if all fields are filled
            guard !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty else {
                return false
            }
            
            // Check if new password meets requirements
            guard newPassword.count >= 8 &&
                    newPassword.contains(where: { $0.isUppercase }) &&
                    newPassword.contains(where: { $0.isNumber }) else {
                return false
            }
            
            // Check if passwords match
            return newPassword == confirmPassword
        }
        
        private func updatePassword() {
            isLoading = true
            errorMessage = nil
            
            Task {
                do {
                    // First verify the current password by attempting to sign in
                    try await authViewModel.verifyCurrentPassword(
                        email: authViewModel.email,
                        currentPassword: currentPassword
                    )
                    
                    // Then update the password with the new method
                    try await authViewModel.updatePassword(newPassword: newPassword)
                    
                    await MainActor.run {
                        isLoading = false
                        showingSuccessAlert = true
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Failed to update password: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}
