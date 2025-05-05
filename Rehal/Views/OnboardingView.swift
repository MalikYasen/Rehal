import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    // Onboarding pages
    let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "map.fill",
            title: "Discover Bahrain",
            description: "Explore the best attractions, restaurants, and hidden gems throughout Bahrain."
        ),
        OnboardingPage(
            image: "star.fill",
            title: "Reviews & Ratings",
            description: "Read reviews from other travelers and share your own experiences."
        ),
        OnboardingPage(
            image: "heart.fill",
            title: "Save Favorites",
            description: "Keep track of your favorite places for easy access on your next adventure."
        ),
        OnboardingPage(
            image: "bell.fill",
            title: "Stay Updated",
            description: "Get notifications about new attractions and events happening around you."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background color
            logoPurple.ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showOnboarding = false
                    }) {
                        Text("Skip")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                    }
                    .padding([.top, .trailing], 20)
                }
                
                // Logo
                Image("RehalLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 20)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 30) {
                            Image(systemName: pages[index].image)
                                .font(.system(size: 100))
                                .foregroundColor(.white)
                            
                            Text(pages[index].title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(pages[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 40)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 10, height: 10)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Next/Start button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        showOnboarding = false
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(logoPurple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

// Onboarding page model
struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
}
