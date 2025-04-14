//
//  LoginView.swift
//  Rehalltest
//
//  Created by Malik Yaseen on 12/04/2025.
//

import SwiftUI
import Supabase // <-- Import Supabase

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

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

    var body: some View {
        NavigationView {
            ZStack {
                logoPurple.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Logo
                    Image("RehalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .padding(.bottom, 30)

                    // Input Fields
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .foregroundColor(.black)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .textContentType(.password)
                        .foregroundColor(.black)

                    // --- Display Error Message ---
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                            .padding(.horizontal) // Ensure error text wraps
                    }
                    // --- End Display Error Message ---

                    // --- Updated Login Button ---
                    Button {
                        // Call the login function
                        loginUser()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: logoPurple))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(logoPurple)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top)
                    .disabled(isLoading) // Disable button while loading
                    // --- End Updated Login Button ---

                    // Forgot Password Link (remains the same)
                    NavigationLink(destination: ForgotPasswordView()) {
                         Text("Forgot Password?")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 5)

                    Spacer() // Pushes links down

                    // Navigation to Sign Up View (remains the same)
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))

                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom)

                } // End VStack
                .padding(.horizontal)

            } // End ZStack
            .navigationBarHidden(true)
        } // End NavigationView
        .navigationViewStyle(.stack) // Use stack style for consistent navigation
    }

    // --- Login Function ---
    func loginUser() {
        // Basic Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }

        isLoading = true
        errorMessage = nil // Clear previous errors

        Task {
            do {
                guard let supabase = supabase else {
                    errorMessage = "Database connection error. Please try again later."
                    print("❌ Supabase client not initialized")
                    isLoading = false
                    return
                }

                // Call Supabase signIn
                _ = try await supabase.auth.signIn(
                    email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )

                // Handle Success
                isLoading = false
                print("✅ Login successful!")
                // TODO: Implement session handling and navigation
                // For now, the user is logged in, but the UI doesn't change.
                // We need to add logic to observe the auth state and show the main app content.

            } catch {
                // Handle Failure
                isLoading = false
                errorMessage = "Login failed: \(error.localizedDescription)" // Show Supabase error
                print("❌ Login error: \(error.localizedDescription)")
            }
        }
    }
    // --- End Login Function ---
}

// Preview Provider
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        // You can create a dummy client for previews if needed
        // let dummyClient = SupabaseClient(supabaseURL: URL(string: "http://localhost:54321")!, supabaseKey: "dummykey")
        LoginView()
         // .environment(\.supabaseClient, dummyClient)
    }
}
