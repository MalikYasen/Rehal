import SwiftUI
import Supabase

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some View {
        ZStack {
            if !authViewModel.isAuthenticated {
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
    }
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
