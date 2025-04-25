import SwiftUI
import Supabase

struct ProfileView: View {
    @State private var notificationsEnabled = true
    @State private var showingLogoutAlert = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Define the custom purple color (same as login page)
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Profile")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(logoPurple)
            
            // Profile info section
            HStack(spacing: 15) {
                // Profile image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .padding(.leading)
                
                VStack(alignment: .leading) {
                    // Use the display name from Supabase
                    Text(authViewModel.displayName)
                        .font(.headline)
                    
                    // Use the email from Supabase
                    Text(authViewModel.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    // Action for edit profile
                }) {
                    HStack {
                        Text("Edit Profile")
                            .font(.subheadline)
                        
                        Image(systemName: "chevron.right")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.trailing)
            }
            .padding(.vertical)
            
            // Preferences section
            VStack(spacing: 0) {
                Text("PREFERENCES")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                // Notifications row
                HStack {
                    Image(systemName: "bell.fill")
                        .frame(width: 30)
                    
                    Text("Notifications")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                }
                .padding()
                .background(Color.white)
                
                Divider()
                
                // Privacy row
                Button(action: {
                    // Action for privacy
                }) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .frame(width: 30)
                        
                        Text("Privacy")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                }
                
                Divider()
                
                // Information row
                Button(action: {
                    // Action for information
                }) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .frame(width: 30)
                        
                        Text("Information")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                }
                
                Divider()
                
                // Logout row
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .frame(width: 30)
                        
                        Text("Logout")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            Spacer()
        }
        .edgesIgnoringSafeArea(.top) // Only ignore top safe area
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    Task {
                        await authViewModel.signOut()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
