import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Favorites")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(logoPurple)
            
            if !authViewModel.isAuthenticated {
                // Not logged in view
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    
                    Text("Sign in to view your favorites")
                        .font(.headline)
                    
                    Text("Your favorite attractions will appear here once you sign in")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    NavigationLink(destination: LoginView()) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 50)
                            .padding(.vertical, 12)
                            .background(logoPurple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoading {
                // Loading view
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Loading your favorites...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if attractionViewModel.favoriteAttractions.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "heart")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    
                    Text("No favorites yet")
                        .font(.headline)
                    
                    Text("Your favorite attractions will appear here after you mark them with the heart icon")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    NavigationLink(destination: HomeView()) {
                        Text("Explore Attractions")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 50)
                            .padding(.vertical, 12)
                            .background(logoPurple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Favorites list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(attractionViewModel.favoriteAttractions) { attraction in
                            NavigationLink(destination: AttractionDetailView(attraction: attraction)) {
                                HorizontalAttractionCard(attraction: attraction)
                                    .environmentObject(attractionViewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            if let userId = authViewModel.session?.user.id {
                isLoading = true
                Task {
                    await attractionViewModel.fetchFavorites(for: userId)
                    isLoading = false
                }
            }
        }
    }
}

struct HorizontalAttractionCard: View {
    let attraction: Attraction
    @EnvironmentObject private var attractionViewModel: AttractionViewModel
    
    // Supabase storage base URL
    private let storageBaseUrl = "https://vulhxauybqrvunqkazty.supabase.co/storage/v1/object/public/rehal-storage/attractions/"
    
    // Function to get proper URL for image
    private func getFullImageUrl(_ imageUrl: String) -> URL? {
        // If it's already a full URL that starts with http, use it directly
        if imageUrl.starts(with: "http") {
            return URL(string: imageUrl)
        }
        
        // Otherwise, append the filename to the base URL
        return URL(string: storageBaseUrl + imageUrl)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let firstImage = attraction.images?.first, !firstImage.isEmpty {
                if let url = getFullImageUrl(firstImage) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .clipped()
                        case .failure(let error):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                        Text("Error")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                )
                            .onAppear {
                                print("Image failed to load: \(url) - Error: \(error.localizedDescription)")
                            }
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                        }
                    }
                    .id(url) // Use id to force refresh when URL changes
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                Text("Invalid URL")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        )
                        .onAppear {
                            print("Invalid image URL: \(firstImage)")
                        }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                            Text("No image")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(attraction.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(attraction.category)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(attraction.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    // Use attractionRatings dictionary or default to 0.0
                    Text(String(format: "%.1f", attractionViewModel.attractionRatings[attraction.id] ?? 0.0))
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            // Debug logging
            if let images = attraction.images {
                print("Attraction \(attraction.name) has \(images.count) images: \(images.first ?? "none")")
            } else {
                print("Attraction \(attraction.name) has no images")
            }
        }
    }
}
