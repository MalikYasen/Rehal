import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = false
    @Published var error: String?
    @Published var avatarUrl: String?
    
    let supabase: SupabaseClient
    
    var isAuthenticated: Bool {
        session != nil
    }
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        
        // Check for existing session when app starts
        Task {
            await checkSession()
        }
    }
    
    private func checkSession() async {
        do {
            // Try to get the current session
            session = try await supabase.auth.session
            
            // If session exists, fetch the user profile including the avatar URL
            if session != nil {
                await fetchUserProfile()
            }
        } catch {
            session = nil
            print("Error checking session: \(error)")
        }
    }
    
    private func fetchUserProfile() async {
        guard let userId = session?.user.id else { return }
        
        do {
            let response = try await supabase.from("profiles")
                .select("avatar_url, full_name")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            do {
                if let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                    if let avatar = json["avatar_url"] as? String {
                        self.avatarUrl = avatar
                    }
                }
            } catch {
                print("Error parsing profile data: \(error)")
            }
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Sign up the user with proper AnyJSON formatting
            let userMetadata = ["full_name": AnyJSON.string(fullName)]
            
            let signUpResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: userMetadata
            )
            
            // Since user is not optional, access directly
            let userId = signUpResponse.user.id
            
            // Add user to profiles table
            try await supabase.from("profiles")
                .insert([
                    "id": userId.uuidString,
                    "full_name": fullName
                ])
                .execute()
            
            // Automatically sign in the user after successful signup
            let signInSession = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Update the session directly
            self.session = signInSession
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Sign up failed: \(error.localizedDescription)"
            return false
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            // The response itself is the session
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Update the session directly
            self.session = session
            
            // Fetch user profile after successful login
            await fetchUserProfile()
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Login failed: \(error.localizedDescription)"
        }
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            session = nil
            avatarUrl = nil
        } catch {
            self.error = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Failed to send reset link: \(error.localizedDescription)"
            return false
        }
    }
    
    var displayName: String {
        if let user = session?.user,
           let metadata = user.userMetadata as? [String: Any],
           let fullName = metadata["full_name"] as? String {
            return fullName
        }
        return "User"
    }
    
    var email: String {
        session?.user.email ?? "No email"
    }
    // Expose method for changing password
    func updatePassword(newPassword: String) async throws {
        // Create a UserAttributes object with the password
        let attributes = UserAttributes(password: newPassword)
        
        // Update the user with proper syntax
        try await supabase.auth.update(user: attributes)
    }
    
    // Method to verify current password by attempting to sign in
    func verifyCurrentPassword(email: String, currentPassword: String) async throws -> Bool {
        do {
            // Try to sign in with current credentials
            _ = try await supabase.auth.signIn(
                email: email,
                password: currentPassword
            )
            return true
        } catch {
            throw error
        }
    }
}
