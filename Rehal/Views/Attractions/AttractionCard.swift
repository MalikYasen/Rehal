import SwiftUI

struct AttractionCard: View {
    let attraction: Attraction
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let firstImage = attraction.images?.first, !firstImage.isEmpty {
                AsyncImage(url: URL(string: firstImage)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill) // Changed from .cover to .fill
                            .frame(height: 140)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
                .cornerRadius(12, corners: [.topLeft, .topRight])
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
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
                
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("4.5")  // This would be calculated from reviews
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
