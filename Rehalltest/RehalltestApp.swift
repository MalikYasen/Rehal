//
//  RehalltestApp.swift
//  Rehalltest
//
//  Created by Malik Yaseen on 12/04/2025.
//RehalltestApp

import SwiftUI
import Supabase // <-- Import Supabase

@main
struct RehalltestApp: App {

    // --- Initialize Supabase Client ---
    // Replace with your actual URL and Key from Supabase Project Settings > API
    let supabase = SupabaseClient(
      supabaseURL: URL(string: "https://vulhxauybqrvunqkazty.supabase.co")!,
      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1bGh4YXV5YnFydnVucWthenR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0NjY3MDQsImV4cCI6MjA2MDA0MjcwNH0.kj3L0XCFb_GnJtXAojhjD2cOvm3T6mYcXRgF5hLDrXs"
    )
    // --- End Initialization ---

    var body: some Scene {
        WindowGroup {
            // We'll wrap LoginView later to pass the client down
            LoginView()
                // Pass the client into the SwiftUI environment
                .environment(\.supabaseClient, supabase)
        }
    }
}

// --- Add SupabaseClient to SwiftUI Environment ---
// Define a key to access the client in the environment
private struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient? = nil // Default to nil if not set
}

// Extend EnvironmentValues to provide easy access
extension EnvironmentValues {
    var supabaseClient: SupabaseClient? {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
