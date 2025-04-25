import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var showSuccessAlert = false
    
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
                Image("Forgotpassord")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 30)
                
                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                Text("Enter your email and we'll send you a link to reset your password.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
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
                
                // Error message (if any)
                if let error = authViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Submit button
                Button {
                    resetPassword()
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: logoPurple))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    } else {
                        Text("Submit")
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
        }
        .alert("Reset Link Sent", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Dismiss the forgot password view and go back to login
                dismiss()
            }
        } message: {
            Text("Please check your email for instructions to reset your password.")
        }
    }
    
    // Reset Password function
    func resetPassword() {
        // Basic validation
        guard !email.isEmpty else {
            authViewModel.error = "Please enter your email."
            return
        }
        
        Task {
            let success = await authViewModel.resetPassword(email: email)
            
            if success {
                showSuccessAlert = true
            }
        }
    }
}
