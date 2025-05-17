import SwiftUI

struct AttractionCard: View {
    let attraction: Attraction
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let firstImage = attraction.images?.first, !firstImage.isEmpty {
                // Create proper image URL
                let imageUrl = getProperImageURL(firstImage)
                
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minHeight: 120, maxHeight: 160)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                    
                                    Text("Image failed to load")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                    }
                }
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .onAppear {
                    // Use onAppear for debugging
                    print("Loading image from: \(imageUrl?.absoluteString ?? "nil")")
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(attraction.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Category badge
                Text(getCategoryTag(for: attraction))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(getCategoryColor(for: attraction).opacity(0.15))
                    .foregroundColor(getCategoryColor(for: attraction))
                    .cornerRadius(4)
                
                Spacer(minLength: 2)
                
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", attractionViewModel.getAverageRating(for: attraction.id)))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Helper function to get the proper image URL
    private func getProperImageURL(_ urlString: String) -> URL? {
        if urlString.hasPrefix("http") {
            return URL(string: urlString)
        } else {
            // Use your Supabase storage URL structure
            return URL(string: "https://vulhxauybqrvunqkazty.supabase.co/storage/v1/object/public/rehal-storage/attractions/\(urlString)")

        }
    }
    
    private func getCategoryTag(for attraction: Attraction) -> String {
        if let subcategory = attraction.subcategory, !subcategory.isEmpty {
            return subcategory
        } else {
            return attraction.category
        }
    }
    
    private func getCategoryColor(for attraction: Attraction) -> Color {
        let category = attraction.category.lowercased()
        if category.contains("restaurant") {
            return .orange
        } else if category.contains("histor") {
            return .blue
        } else if category.contains("beach") {
            return .teal
        } else if category.contains("shop") {
            return .purple
        } else if category.contains("entertain") {
            return .pink
        } else {
            return .gray
        }
    }
}
