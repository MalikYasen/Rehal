import SwiftUI

struct AttractionCard: View {
    let attraction: Attraction
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationLink(destination: AttractionDetailView(attraction: attraction)) {
            VStack(alignment: .leading) {
                // Image placeholder (would be replaced with actual image loading)
                if let firstImage = attraction.images?.first, !firstImage.isEmpty {
                    // In a real app, load the image from Supabase storage
                    AsyncImage(url: URL(string: firstImage)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 180)
                                .cornerRadius(12)
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(12)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 180)
                                .cornerRadius(12)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 180)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 180)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(attraction.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        // In a real app, you'd fetch the average rating from the reviews table
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("4.5")  // This would be calculated from reviews
                            .foregroundColor(.primary)
                        Text("(120 reviews)")  // This would be the count of reviews
                            .foregroundColor(.gray)
                            .font(.caption)
                        Spacer()
                        if let location = attraction.location {
                            // Calculate distance (in a real app)
                            Text("2.5 km")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("\(attraction.category)\(attraction.subcategory != nil ? " • \(attraction.subcategory!)" : "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
}
