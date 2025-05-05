import SwiftUI

struct InformationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContactForm = false
    
    // Define the custom purple color (same as login page)
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // About the app section
                VStack(alignment: .leading, spacing: 12) {
                    Label("About Rehal", systemImage: "info.circle.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(logoPurple)
                    
                    Text("Rehal is your local travel guide for Bahrain, designed to help you discover hidden gems, popular attractions, and amazing experiences throughout the country.")
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Divider()
                    .padding(.horizontal)
                
                // Features section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Features", systemImage: "star.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(logoPurple)
                    
                    FeatureRow(icon: "magnifyingglass", title: "Discover Attractions", description: "Find the best places to visit in Bahrain")
                    
                    FeatureRow(icon: "star.bubble", title: "Reviews & Ratings", description: "Read and write reviews for local attractions")
                    
                    FeatureRow(icon: "heart.fill", title: "Favorites", description: "Save your favorite places for quick access")
                    
                    FeatureRow(icon: "map.fill", title: "Interactive Maps", description: "Get directions to any attraction")
                    
                    FeatureRow(icon: "bell.fill", title: "Notifications", description: "Stay updated about new places and events")
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Team section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Meet the Team", systemImage: "person.3.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(logoPurple)
                    
                    Text("Rehal was created by Malik Yaseen as part of an ICT Project at Bahrain Polytechnic. Our team is dedicated to showcasing the beauty and culture of Bahrain through this interactive local travel guide.")
                    
                    PersonRow(name: "Malik Yaseen", role: "Project Manager & Developer")
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Contact section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Contact Us", systemImage: "envelope.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(logoPurple)
                    
                    Text("Have questions, feedback, or suggestions? We'd love to hear from you!")
                    
                    Button(action: {
                        showContactForm = true
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Contact Us")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(logoPurple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Legal section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Legal", systemImage: "doc.text.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(logoPurple)
                    
                    NavigationLink(destination: PrivacyView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .frame(width: 30)
                            
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                    }
                    
                    NavigationLink(destination: TermsView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .frame(width: 30)
                            
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal)
                
                // Credits and acknowledgments
                VStack(alignment: .center, spacing: 8) {
                    Text("Made with ❤️ in Bahrain")
                        .font(.subheadline)
                    
                    Text("© 2025 Rehal. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .navigationBarTitle("Information", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(logoPurple)
        })
        .sheet(isPresented: $showContactForm) {
            ContactFormView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.purple)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PersonRow: View {
    let name: String
    let role: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.purple.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ContactFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Message")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }
                
                Button(action: {
                    submitForm()
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(isFormValid ? .white : .gray)
                        .padding()
                        .background(isFormValid ? logoPurple : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .listRowBackground(Color.clear)
            }
            .navigationBarTitle("Contact Us", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Thank You"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@") && !message.isEmpty
    }
    
    private func submitForm() {
        // In a real app, this would send the message to a backend
        alertMessage = "Thanks \(name)! We've received your message and will get back to you soon."
        showingAlert = true
    }
}

// Placeholder for Terms View
struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("Last updated: May 1, 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                Text("These Terms of Service govern your use of Rehal, a mobile application provided by Rehal Team.")
                    .padding(.bottom, 10)
                
                // Placeholder content for Terms of Service
                Text("By using our app, you agree to these terms. Please read them carefully.")
                
                // Add more terms content here...
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationBarTitle("Terms of Service", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(logoPurple)
        })
    }
}

struct InformationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InformationView()
        }
    }
}
