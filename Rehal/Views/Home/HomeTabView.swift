import SwiftUI

struct HomeTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                HomeView()
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Favorites Tab
            NavigationView {
                FavoritesView()
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Favorites")
            }
            .tag(1)
            
            // Stats Tab (modified with qualified path)
            NavigationView {
                // Use fully qualified path to avoid scope issues
                StatsView()
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Stats")
            }
            .tag(2)
            
            // Profile Tab
            NavigationView {
                ProfileView()
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(logoPurple) // Use the app's primary color for selected tabs
        .onChange(of: selectedTab) { _, newTab in
            // If the user selects the favorites tab and isn't logged in,
            // prompt them to log in
            if (newTab == 1 || newTab == 2) && !authViewModel.isAuthenticated {
                // In a real app, you might want to present a login view
                // or show an alert, but for simplicity, we'll just switch back to home
                // selectedTab = 0
            }
        }
    }
}
