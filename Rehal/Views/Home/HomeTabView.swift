import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            // Home Tab
            NavigationView {
                HomeView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .accentColor(.purple) // Use your app's primary color
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTabView()
    }
}
