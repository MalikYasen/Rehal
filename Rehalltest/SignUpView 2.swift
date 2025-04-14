//
//  SignUpView 2.swift
//  Rehalltest
//
//  Created by Malik Yaseen on 13/04/2025.
//


import SwiftUI
import Supabase // Import Supabase

struct SignUpView: View {
    // State variables for user input
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // --- Supabase Integration ---
    @Environment(\.supabaseClient) var supabase // Access the client
    @State private var isLoading = false // Track loading state
    @State private var errorMessage: String? // Store potential error messages
    // --- End Supabase Integration ---

    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )

    // Environment variable to dismiss the view
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            logoPurple.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 15) {

                    // Title
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 30)

                    // Input Fields
                    TextField("First Name", text: $firstName)
                         .padding().background(Color.white.opacity(0.9)).cornerRadius(8).textContentType(.givenName).foregroundColor(.black)
                    TextField("Last Name", text: $lastName)
                         .padding().background(Color.white.opacity(0.9)).cornerRadius(8).textContentType(.familyName).foregroundColor(.black)
                    TextField("Email", text: $email)
                         .padding().background(Color.white.opacity(0.9)).cornerRadius(8).keyboardType(.emailAddress).autocapitalization(.none).textContentType(.emailAddress).foregroundColor(.black)
                    TextField("Phone Number", text: $phoneNumber)
                         .padding().background(Color.white.opacity(0.9)).cornerRadius(8).keyboardType(.phonePad).textContentType(.telephoneNumber).foregroundColor(.black)
                    SecureField("Password", text: $password)
                         .padding().background(Color.white.opacity(0.9)).cornerRadius(8).textContentType(.newPassword).foregroundColor(.black)
                    SecureField("Confirm Password", text: $confirmPassword)
                         .padding().background(Color.white.opacity(0.9)).cornerRadius(8).textContentType(.newPassword).foregroundColor(.black)

                    // Display Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                            .padding(.horizontal) // Ensure error text wraps if long
                    }

                    // Updated Sign Up Button
                    Button {
                        signUpUser() // Call the sign up function
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: logoPurple))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(logoPurple)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 20)
                    .disabled(isLoading) // Disable button while loading

                    // Link back to Login View
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        Button {
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom)

                } // End of VStack
                .padding(.horizontal)
            } // End of ScrollView
        } // End of ZStack
        .navigationBarBackButtonHidden(true) // Keep custom back button behavior
    }

    // --- Sign Up Function ---
    func signUpUser() {
        // Basic Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        // Consider adding email format validation
        // Consider adding password strength validation

        isLoading = true
        errorMessage = nil // Clear previous errors

        Task { // Use Task for async operation
            do {
                // Check if supabase client exists
                guard let supabase = supabase else {
                    // You might want a more user-friendly error here
                    errorMessage = "Database connection error. Please try again later."
                    print("❌ Supabase client not initialized")
                    isLoading = false
                    return
                }

                // Prepare user metadata (Corrected Type)
                let userMetaData: [String: AnyJSON] = [
                    "first_name": .string(firstName),
                    "last_name": .string(lastName),
                    "phone_number": .string(phoneNumber) // Ensure phone number is treated as string
                ]

                // Call Supabase signUp
                _ = try await supabase.auth.signUp(
                    email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    data: userMetaData // Pass the correctly typed dictionary
                )

                // Handle Success
                isLoading = false
                print("✅ Sign up successful! Check email for confirmation if enabled.")
                // TODO: Decide action after sign up.
                // If email confirmation is ON: Show a message "Please check your email..."
                // If email confirmation is OFF: User is logged in, potentially navigate to main app view.
                // For now, just go back to Login:
                self.presentationMode.wrappedValue.dismiss()

            } catch {
                // Handle Failure
                isLoading = false
                // Provide more user-friendly errors if possible
                errorMessage = "Sign up failed: \(error.localizedDescription)"
                print("❌ Sign up error: \(error.localizedDescription)")
            }
        }
    }
    // --- End Sign Up Function ---
}

// Preview Provider
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // You can create a dummy client for previews if needed
            // let dummyClient = SupabaseClient(supabaseURL: URL(string: "http://localhost:54321")!, supabaseKey: "dummykey")
            SignUpView()
             // .environment(\.supabaseClient, dummyClient)
        }
    }
}