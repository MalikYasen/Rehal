import SwiftUI
import Supabase

struct ProfileView: View {
    @State private var notificationsEnabled = true
    @State private var showingLogoutAlert = false
    @State private var isLoading = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        // Remove the NavigationView wrap since we're already inside one from HomeTabView
        VStack(spacing: 0) {
            // Header
            Text("Profile")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(logoPurple)
            
            ScrollView {
                // Profile info section
                HStack(spacing: 15) {
                    // Profile image with proper loading from URL
                    Group {
                        if let avatarUrl = authViewModel.avatarUrl, !avatarUrl.isEmpty {
                            AsyncImage(url: URL(string: avatarUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_), .empty:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .foregroundColor(logoPurple.opacity(0.7))
                                @unknown default:
                                    ProgressView()
                                        .tint(logoPurple)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .foregroundColor(logoPurple.opacity(0.7))
                        }
                    }
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
                    
                    // Edit Profile row - Moved here for better navigation
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(logoPurple)
                                .frame(width: 30)
                            
                            Text("Edit Profile")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    
                    Divider()
                    
                    // Notifications row
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(logoPurple)
                            .frame(width: 30)
                        
                        Text("Notifications")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(logoPurple)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Theme/Appearance row
                    NavigationLink(destination: ThemeSettingsView()) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(logoPurple)
                                .frame(width: 30)
                            
                            Text("Appearance")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(themeManager.colorSchemePreference.displayName)
                                .foregroundColor(.gray)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    
                    Divider()
                    
                    // Privacy row
                    NavigationLink(destination: PrivacyView()) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(logoPurple)
                                .frame(width: 30)
                            
                            Text("Privacy")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    
                    Divider()
                    
                    // Favorites row
                    NavigationLink(destination: FavoritesView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(logoPurple)
                                .frame(width: 30)
                            
                            Text("My Favorites")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    
                    Divider()
                    
                    // Information row
                    NavigationLink(destination: InformationView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(logoPurple)
                                .frame(width: 30)
                            
                            Text("Information")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    
                    Divider()
                    
                    // Logout row
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .frame(width: 30)
                            
                            Text("Logout")
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                
                // Version info at bottom
                VStack {
                    Text("Rehal v1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    
                    Text("Made with ❤️ in Bahrain")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
            }
        }
        .edgesIgnoringSafeArea(.top) // Only ignore top safe area for the header
        .background(Color(UIColor.systemGroupedBackground))
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    isLoading = true
                    Task {
                        await authViewModel.signOut()
                        isLoading = false
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
    }
}

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        List {
            ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                Button(action: {
                    themeManager.colorSchemePreference = preference
                }) {
                    HStack {
                        Text(preference.displayName)
                        
                        Spacer()
                        
                        if themeManager.colorSchemePreference == preference {
                            Image(systemName: "checkmark")
                                .foregroundColor(logoPurple)
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
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
