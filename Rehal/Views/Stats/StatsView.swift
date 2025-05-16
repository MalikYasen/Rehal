import SwiftUI

struct StatsView: View {
    @EnvironmentObject var reviewViewModel: ReviewViewModel
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    @State private var isLoading = true
    @State private var ratingData: [RatingData] = []
    @State private var totalReviews = 0
    @State private var averageRating = 0.0
    
    // Define the custom purple color (same as elsewhere in the app)
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Statistics")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(logoPurple)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Stats overview
                    HStack(spacing: 20) {
                        // Attractions count
                        StatCard(
                            value: "\(attractionViewModel.attractions.count)",
                            label: "Attractions",
                            icon: "map",
                            color: .blue
                        )
                        
                        // Reviews count
                        StatCard(
                            value: "\(totalReviews)",
                            label: "Reviews",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        // Average rating
                        StatCard(
                            value: String(format: "%.1f", averageRating),
                            label: "Avg Rating",
                            icon: "chart.bar.fill",
                            color: .green
                        )
                    }
                    .padding(.top, 16)
                    
                    // Ratings distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ratings Distribution")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 300)
                        } else if ratingData.isEmpty {
                            Text("No ratings data available")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            // Ratings chart (simple bar chart since we don't use Charts)
                            VStack(spacing: 16) {
                                ForEach(ratingData) { data in
                                    HStack {
                                        Text("\(data.rating)★")
                                            .font(.subheadline)
                                            .foregroundColor(.yellow)
                                            .frame(width: 40)
                                        
                                        // Calculate width based on count compared to maximum
                                        let maxCount = ratingData.map { $0.count }.max() ?? 1
                                        let widthRatio = Double(data.count) / Double(maxCount)
                                        
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 24)
                                                .cornerRadius(4)
                                            
                                            Rectangle()
                                                .fill(Color.yellow)
                                                .frame(width: max(CGFloat(widthRatio) * 200, 4), height: 24)
                                                .cornerRadius(4)
                                        }
                                        
                                        Text("\(data.count)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .frame(width: 40)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Top rated attractions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Rated Attractions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if attractionViewModel.attractions.isEmpty {
                            Text("No attractions data available")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(getTopRatedAttractions().prefix(3), id: \.id) { attraction in
                                NavigationLink(destination: AttractionDetailView(attraction: attraction)) {
                                    TopAttractionRow(attraction: attraction)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Info card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Statistics")
                            .font(.headline)
                        
                        Text("This dashboard shows statistics about attractions and user reviews in the Rehal app. The data is updated in real-time as users interact with the app.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        
        // In a real app, you would fetch this data from your backend
        // For this example, we'll generate some sample data
        
        Task {
            // Fetch all attractions if not loaded yet
            if attractionViewModel.attractions.isEmpty {
                await attractionViewModel.fetchAttractions()
            }
            
            // Generate rating distribution data
            var ratings: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
            var total = 0
            var sum = 0
            
            // Normally you would fetch this from the backend or aggregate from reviews
            // For now, we'll generate some sample data based on what we might have
            for attraction in attractionViewModel.attractions {
                // Fetch reviews for each attraction
                await reviewViewModel.fetchReviews(for: attraction.id)
                
                // Update ratings counts
                for review in reviewViewModel.reviews {
                    ratings[review.rating, default: 0] += 1
                    total += 1
                    sum += review.rating
                }
            }
            
            // Calculate average rating
            averageRating = total > 0 ? Double(sum) / Double(total) : 0.0
            totalReviews = total
            
            // Create chart data
            ratingData = (1...5).map { rating in
                RatingData(rating: rating, count: ratings[rating, default: 0])
            }
            
            isLoading = false
        }
    }
    
    private func getTopRatedAttractions() -> [Attraction] {
        // In a real app, you would sort attractions by their average rating
        // For now, we'll just return the first few attractions
        return Array(attractionViewModel.attractions.prefix(3))
    }
}

// Model for rating chart data
struct RatingData: Identifiable {
    let id = UUID()
    let rating: Int
    let count: Int
}

// Reusable statistic card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
}

// Top attraction row component
struct TopAttractionRow: View {
    let attraction: Attraction
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let firstImage = attraction.images?.first, !firstImage.isEmpty {
                AsyncImage(url: URL(string: firstImage)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(attraction.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(attraction.category)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // Rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= 4 ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    
                    Text("4.0")  // Placeholder rating
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}
