//
//  SignUpView.swift
//  Rehalltest
//
//  Created by Malik Yaseen on 12/04/2025.
//

import SwiftUI
import Supabase

struct SignUpView: View {
    // State variables for user input
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Supabase Integration
    @Environment(\.supabaseClient) var supabase
    @State private var isLoading = false
    @State private var errorMessage: String?

    // --- State for Success Alert ---
    @State private var showSuccessAlert = false
    // --- End State for Success Alert ---

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

            // --- Always show the form now ---
            SignUpFormView(
                firstName: $firstName,
                lastName: $lastName,
                email: $email,
                phoneNumber: $phoneNumber,
                password: $password,
                confirmPassword: $confirmPassword,
                isLoading: $isLoading,
                errorMessage: $errorMessage,
                logoPurple: logoPurple,
                signUpAction: signUpUser,
                // Action for the "Log In" link at the bottom
                loginAction: { presentationMode.wrappedValue.dismiss() }
            )
            // --- End Always show the form ---

        } // End of ZStack
        .navigationBarBackButtonHidden(true)
        // --- Add Success Alert Modifier ---
        .alert("Sign Up Successful", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Action for the OK button: Dismiss the SignUpView
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your account has been created successfully. You can now log in.")
        }
        // --- End Success Alert Modifier ---
    }

    // --- Sign Up Function (Modified Success Handling) ---
    func signUpUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let supabase = supabase else {
                    errorMessage = "Database connection error. Please try again later."
                    print("❌ Supabase client not initialized")
                    isLoading = false
                    return
                }

                let userMetaData: [String: AnyJSON] = [
                    "first_name": .string(firstName),
                    "last_name": .string(lastName),
                    "phone_number": .string(phoneNumber)
                ]

                _ = try await supabase.auth.signUp(
                    email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    data: userMetaData
                    // No options needed here since email confirmation is off
                )

                // --- Handle Success: Show Alert ---
                isLoading = false
                print("✅ Sign up successful! (Email confirmation disabled)")
                showSuccessAlert = true // Trigger the alert
                // --- End Success Handling Change ---

            } catch {
                isLoading = false
                // Display the specific error from Supabase
                errorMessage = "Sign up failed: \(error.localizedDescription)"
                print("❌ Sign up error: \(error.localizedDescription)")
            }
        }
    }
    // --- End Sign Up Function ---
}

// --- SignUpFormView (No changes needed from previous version) ---
struct SignUpFormView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var phoneNumber: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    let logoPurple: Color
    let signUpAction: () -> Void
    let loginAction: () -> Void // For the "Log In" link

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Create Account")
                    .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                    .padding(.top, 40).padding(.bottom, 30)

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

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red).font(.caption)
                        .padding(.top, 5).padding(.horizontal)
                }

                Button(action: signUpAction) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: logoPurple))
                            .frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(8)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                            .foregroundColor(logoPurple).background(Color.white).cornerRadius(8)
                    }
                }
                .padding(.top, 20)
                .disabled(isLoading)

                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.white.opacity(0.8))
                    Button(action: loginAction) { // This button dismisses the view
                        Text("Log In")
                            .fontWeight(.semibold).foregroundColor(.white)
                    }
                }
                .padding(.top, 10).padding(.bottom)

            }
            .padding(.horizontal)
        }
    }
}


// --- ConfirmationMessageView is NO LONGER NEEDED ---
// You can delete the ConfirmationMessageView struct entirely.


// Preview Provider
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignUpView()
             // .environment(\.supabaseClient, dummyClient)
        }
    }
}
