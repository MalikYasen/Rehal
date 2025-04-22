import SwiftUI
import Supabase

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        // Check if a session exists in the AuthViewModel
        if authViewModel.isAuthenticated {
            // User is logged in - show main app content
            HomeTabView()
        } else {
            // User is logged out - show login flow
            LoginView()
        }
    }
}
