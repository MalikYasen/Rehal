import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = false
    @Published var error: String?
    private var pollingTask: Task<Void, Never>? = nil
    private let supabase: SupabaseClient
    
    // Expose the Supabase client for other views to use
    var supabaseClient: SupabaseClient {
        return supabase
    }
    
    // Polling interval in seconds
    private let pollingInterval: UInt64 = 5

    init(supabase: SupabaseClient) {
        self.supabase = supabase
        print("AuthViewModel initialized")

        // Perform initial session check and start polling
        Task {
            await checkSession()
            startSessionPolling()
        }
    }
    
    // Check the current session state
    private func checkSession() async {
        do {
            print("Checking session...")
            let currentSession = try await supabase.auth.session
            print("Session check result: \(currentSession != nil ? "Session found" : "No session")")
            
            // Only update if there's an actual change to avoid unnecessary UI updates
            if (session == nil && currentSession != nil) ||
               (session != nil && currentSession == nil) {
                print("Session state changed: \(currentSession == nil ? "Logged out" : "Logged in")")
                session = currentSession
            }
        } catch {
            print("❌ Error checking session: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            // If there's an error, assume logged out
            if session != nil {
                session = nil
            }
        }
    }

    // Start polling for session changes
    private func startSessionPolling() {
        print("Starting session polling...")
        
        // Cancel any existing polling task
        pollingTask?.cancel()
        
        // Create a new polling task
        pollingTask = Task {
            while !Task.isCancelled {
                // Check the session
                await checkSession()
                
                // Wait for the polling interval
                do {
                    try await Task.sleep(nanoseconds: pollingInterval * 1_000_000_000)
                } catch {
                    // Sleep was interrupted, likely due to task cancellation
                    break
                }
            }
            
            print("Session polling task finished.")
        }
    }

    // Sign in with email and password
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            _ = try await supabase.auth.signIn(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            isLoading = false
            print("✅ Login successful!")
            return true
        } catch {
            isLoading = false
            
            // Provide a user-friendly error message
            if error.localizedDescription.contains("Invalid login credentials") {
                self.error = "Invalid email or password. Please try again."
            } else {
                self.error = "Login failed: \(error.localizedDescription)"
            }
            
            print("❌ Login error: \(error.localizedDescription)")
            return false
        }
    }

    // Sign up with email and password
    func signUp(email: String, password: String, fullName: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Create user metadata with full name
            let userMetaData: [String: AnyJSON] = [
                "full_name": .string(fullName)
            ]
            
            // Call Supabase signUp method
            _ = try await supabase.auth.signUp(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                data: userMetaData
            )
            
            isLoading = false
            print("✅ Sign up successful! Verification email sent.")
            return true
        } catch {
            isLoading = false
            
            // Provide a user-friendly error message
            if error.localizedDescription.contains("User already registered") {
                self.error = "This email is already registered. Please log in instead."
            } else {
                self.error = "Sign up failed: \(error.localizedDescription)"
            }
            
            print("❌ Sign up error: \(error.localizedDescription)")
            return false
        }
    }

    // Reset password
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(
                email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            isLoading = false
            print("✅ Password reset email sent.")
            return true
        } catch {
            isLoading = false
            self.error = "Failed to send reset link: \(error.localizedDescription)"
            print("❌ Password reset error: \(error.localizedDescription)")
            return false
        }
    }

    // Sign out
    func signOut() async {
        print("Attempting sign out...")
        do {
            try await supabase.auth.signOut()
            print("Sign out successful.")
            session = nil
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            // Force a session check after sign out attempt
            await checkSession()
        }
    }

    // Check if user is authenticated
    var isAuthenticated: Bool {
        session != nil
    }

    // Get user's display name from metadata - FIXED VERSION
    var displayName: String {
        guard let session = session else { return "User" }
        
        // Direct access without optional binding
        let metadata = session.user.userMetadata
        
        // Try to extract the string value
        if let fullNameValue = metadata["full_name"],
           case let .string(fullName) = fullNameValue {
            return fullName
        }
        
        return "User"
    }

    // Get user's email
    var email: String {
        session?.user.email ?? "No email"
    }

    deinit {
        print("AuthViewModel deinitialized. Cancelling polling task.")
        pollingTask?.cancel()
    }
}
