import SwiftUI
import Supabase

@main
struct RehalApp: App {
    // Initialize Supabase client with your project URL and anon key
    private let supabaseClient = SupabaseClient(
        supabaseURL: URL(string: "https://vulhxauybqrvunqkazty.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1bGh4YXV5YnFydnVucWthenR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0NjY3MDQsImV4cCI6MjA2MDA0MjcwNH0.kj3L0XCFb_GnJtXAojhjD2cOvm3T6mYcXRgF5hLDrXs"
    )
    
    // Create the ViewModels
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var attractionViewModel: AttractionViewModel
    @StateObject private var reviewViewModel: ReviewViewModel
    @StateObject private var storageService: StorageService
    @StateObject private var themeManager = ThemeManager()
    
    // Use init() to properly initialize the StateObjects
    init() {
        // Create the ViewModels with the initialized supabaseClient
        let authVM = AuthViewModel(supabase: supabaseClient)
        let attractionVM = AttractionViewModel(supabase: supabaseClient)
        let reviewVM = ReviewViewModel(supabase: supabaseClient)
        let storageVM = StorageService(supabase: supabaseClient)
        
        // Initialize the @StateObjects
        _authViewModel = StateObject(wrappedValue: authVM)
        _attractionViewModel = StateObject(wrappedValue: attractionVM)
        _reviewViewModel = StateObject(wrappedValue: reviewVM)
        _storageService = StateObject(wrappedValue: storageVM)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(attractionViewModel)
                .environmentObject(reviewViewModel)
                .environmentObject(storageService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
