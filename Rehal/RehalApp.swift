import SwiftUI
import Supabase

@main
struct RehalApp: App {
    // Initialize Supabase client with your actual project URL and anon key
    private let supabaseClient = SupabaseClient(
        supabaseURL: URL(string: "https://vulhxauybqrvunqkazty.supabase.co")!,
        supabaseKey: "your-actual-anon-key-here"
    )
    
    // Create the AuthViewModel
    @StateObject private var authViewModel: AuthViewModel
    
    // Use init() to properly initialize the StateObject
    init() {
        // Create the AuthViewModel with the already initialized supabaseClient
        let viewModel = AuthViewModel(supabase: supabaseClient)
        
        // Initialize the @StateObject using _authViewModel
        _authViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
