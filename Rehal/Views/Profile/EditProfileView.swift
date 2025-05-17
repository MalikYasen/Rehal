import SwiftUI
import Supabase

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var fullName: String = ""
    @State private var initialFullName: String = ""  // Store initial value to compare
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    @State private var initialProfileImageSet = false  // Track if profile image was initially set
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
                    ZStack {
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
                            // Default profile icon
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(logoPurple.opacity(0.7))
                                .frame(width: 120, height: 120)
                        }
                        
                        // Camera icon overlay at bottom right
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(logoPurple)
                                        .font(.system(size: 18))
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .offset(x: 40, y: 40)
                    }
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
                            .onChange(of: fullName) { _, newValue in
                                // Only set formChanged if value actually differs from initial
                                formChanged = newValue != initialFullName
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
                // Only show discard alert if there are actual changes
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
            initialFullName = authViewModel.displayName
            fullName = authViewModel.displayName
            
            // Load profile image if available
            if let avatarUrlString = authViewModel.avatarUrl {
                loadProfileImage(from: avatarUrlString)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
                .onChange(of: profileImage) { _, newValue in
                    // Only mark as changed if the image actually changed from initial state
                    if initialProfileImageSet {
                        formChanged = true
                    } else if newValue != nil {
                        formChanged = true
                    }
                }
        }
        .alert(isPresented: $showingDiscardAlert) {
            Alert(
                title: Text("Discard Changes?"),
                message: Text("You have unsaved changes. Are you sure you want to go back?"),
                primaryButton: .destructive(Text("Discard")) {
                    formChanged = false  // Reset flag before dismissing
                    DispatchQueue.main.async {
                        dismiss()  // Use main thread to ensure proper dismissal
                    }
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
    
    // Helper function to load profile image from URL
    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                    self.initialProfileImageSet = true  // Mark that we loaded an initial image
                }
            }
        }.resume()
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
                    
                    // Update the stored initial values to match current values
                    initialFullName = fullName
                    initialProfileImageSet = (profileImage != nil)
                    
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
        try await authViewModel.supabase.auth.update(user: UserAttributes(data: userMetadata))
        
        // Update the fullName in the AuthViewModel to ensure it displays correctly
        await MainActor.run {
            authViewModel.fullName = fullName
        }
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
        
        // Upload the image
        try await authViewModel.supabase.storage
            .from(bucket)
            .upload(
                fileName,
                data: imageData,
                options: fileOptions
            )
        
        // Get the public URL
        let publicURLResponse = try authViewModel.supabase.storage
            .from(bucket)
            .getPublicURL(path: fileName)
        
        // Update the avatar_url in the profiles table
        let avatarUrl = publicURLResponse.absoluteString
        
        try await authViewModel.supabase.from("profiles")
            .update([
                "avatar_url": avatarUrl
            ])
            .eq("id", value: userId.uuidString)
            .execute()
            
        // Update the avatarUrl in the view model as well
        await MainActor.run {
            authViewModel.avatarUrl = avatarUrl
        }
    }
}
