import SwiftUI
import Supabase

// In ContentView.swift
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var isInitializing = true // Add this line
    
    var body: some View {
        ZStack {
            if isInitializing {
                // Add a splash screen or loading indicator
                ZStack {
                    logoPurple.ignoresSafeArea()
                    VStack {
                        Image("RehalLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 20)
                    }
                }
            } else if !authViewModel.isAuthenticated {
                if showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .onDisappear {
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        }
                } else {
                    LoginView()
                }
            } else {
                HomeTabView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: showOnboarding)
        .onAppear {
            // Wait for auth check to complete before showing content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInitializing = false
            }
        }
    }
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel(supabase: SupabaseClient(
                supabaseURL: URL(string: "https://example.com")!,
                supabaseKey: "example-key"
            )))
    }
}
