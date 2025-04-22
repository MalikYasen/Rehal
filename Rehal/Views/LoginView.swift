import SwiftUI
import Supabase

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                // Background color
                logoPurple.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo
                    Image("RehalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 50)
                    
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
                        .textContentType(.password)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                    
                    // Error message (if any)
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Login button
                    Button {
                        loginUser()
                    } label: {
                        if authViewModel.isLoading {
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
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .disabled(authViewModel.isLoading)
                    
                    // Forgot Password link
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .foregroundColor(.white)
                            .underline()
                            .padding(.top, 5)
                    }
                    
                    Spacer()
                    
                    // Sign Up link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // Login function
    func loginUser() {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            authViewModel.error = "Email and password cannot be empty."
            return
        }
        
        Task {
            await authViewModel.signIn(email: email, password: password)
        }
    }
}
