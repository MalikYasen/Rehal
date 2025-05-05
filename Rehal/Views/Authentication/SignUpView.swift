import SwiftUI
import Supabase

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var showSignUpSuccessToast = false
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        ZStack {
            // Background color
            logoPurple.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo
                Image("RehalLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 30)
                
                // Full Name field
                TextField("Full Name", text: $fullName)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .textContentType(.name)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                
                // Email field
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                
                // Password field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .textContentType(.newPassword)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                
                // Confirm Password field
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .textContentType(.newPassword)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                
                // Error message (if any)
                if let error = authViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Sign Up button
                Button {
                    signUpUser()
                } label: {
                    if authViewModel.isLoading {
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
                .padding(.horizontal)
                .padding(.top, 10)
                .disabled(authViewModel.isLoading)
                
                Spacer()
                
                // Back to Login link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.white.opacity(0.8))
                    Button {
                        dismiss()
                    } label: {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.white)
            })
            
            // Success toast notification
            if showSignUpSuccessToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Account created successfully!")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showSignUpSuccessToast)
                .onAppear {
                    // Automatically dismiss the toast after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSignUpSuccessToast = false
                    }
                }
            }
        }
    }
    
    // Sign Up function
    func signUpUser() {
        // Basic validation
        guard !fullName.isEmpty else {
            authViewModel.error = "Please enter your full name."
            return
        }
        
        guard !email.isEmpty else {
            authViewModel.error = "Please enter your email."
            return
        }
        
        guard !password.isEmpty else {
            authViewModel.error = "Please enter a password."
            return
        }
        
        guard password == confirmPassword else {
            authViewModel.error = "Passwords do not match."
            return
        }
        
        guard password.count >= 6 else {
            authViewModel.error = "Password must be at least 6 characters."
            return
        }
        
        Task {
            let success = await authViewModel.signUp(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                fullName: fullName
            )
            
            if success {
                // Show brief success toast instead of an alert
                showSignUpSuccessToast = true
                
                // No need to dismiss - user is now logged in and should continue to the main app
            }
        }
    }
}
