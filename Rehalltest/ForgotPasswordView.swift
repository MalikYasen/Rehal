//
//  ForgotPasswordView.swift
//  Rehalltest
//
//  Created by Malik Yaseen on 12/04/2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    // State variable for the email/mobile input
    @State private var emailOrMobile = ""

    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )

    // Environment variable for dismissing
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack { // Use ZStack for background and layering button
            // --- Background Color ---
            logoPurple
                .ignoresSafeArea()
            // --- End Background Color ---

            VStack(spacing: 20) { // Main vertical layout

                // --- Custom Back Button (Top Left) ---
                HStack { // Use HStack to align button to the left
                    Button {
                        // Action to dismiss the current view
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left") // System back icon
                            .font(.title2.weight(.semibold)) // Style the icon
                            .foregroundColor(.white) // Make icon white
                    }
                    Spacer() // Pushes the button to the left
                }
                .padding(.horizontal) // Add padding around the HStack
                .padding(.top, 10) // Add some padding from the top safe area
                // --- End Custom Back Button ---


                // --- Illustration ---
                // Replace "ForgotPasswordIllustration" with your actual asset name
                Image("Forgotpassord") // Make sure this asset exists
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180) // Adjusted height slightly
                    // Removed top padding as back button adds space
                    .padding(.bottom, 20)
                // --- End Illustration ---

                // --- Title ---
                Text("Forgot Password?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                // --- End Title ---

                // --- Subtitle Text ---
                Text("Don't worry it happens. Please enter the address associated with your account.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                // --- End Subtitle Text ---

                // --- Email/Mobile Input Field ---
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                        .padding(.leading, 12)

                    TextField("Email / Mobile Number", text: $emailOrMobile)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .foregroundColor(.black)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.username)
                }
                .background(Color.white) // White background for the HStack
                .cornerRadius(10) // Rounded corners for the field
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.7), lineWidth: 1) // Blue border
                )
                .padding(.horizontal)
                // --- End Email/Mobile Input Field ---

                // --- Submit Button (White Style) ---
                Button {
                    // TODO: Implement actual password reset logic
                    print("Submit password reset tapped for: \(emailOrMobile)")
                } label: {
                    Text("Submit")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity) // Full width
                        .padding()
                        .foregroundColor(logoPurple) // Purple text color
                        .background(Color.white)    // White background color
                        .cornerRadius(10)
                }
                .padding(.horizontal) // Padding around the button
                .padding(.top, 10) // Space above button
                // --- End Submit Button ---

                Spacer() // Pushes content up

            } // End VStack

        } // End ZStack
        // --- Navigation Bar Configuration ---
        // We hide the default navigation bar AND its back button
        // because we now have a custom one in the content.
        .navigationBarHidden(true)
        // --- End Navigation Bar Configuration ---
    }
}

// --- Preview Provider ---
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview still needs NavigationView context if pushed
        NavigationView {
            ForgotPasswordView()
        }
    }
}
