import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .topRated
    @State private var selectedCategory: Category? = nil
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case topRated = "Top Rated"
        case newest = "Newest"
        case popular = "Popular"
        
        var id: String { self.rawValue }
    }
    
    enum Category: String, CaseIterable, Identifiable {
        case restaurants = "Restaurants"
        case historical = "Historical Sites"
        case beaches = "Beaches"
        case shopping = "Shopping"
        case entertainment = "Entertainment"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .restaurants: return "fork.knife"
            case .historical: return "building.columns"
            case .beaches: return "umbrella.beach"
            case .shopping: return "bag"
            case .entertainment: return "ticket"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with logo
                HStack {
                    Image("RehalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                    
                    Spacer()
                    
                    Text("Discover Bahrain")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                
                // Search and filter bar
                VStack(spacing: 10) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search attractions", text: $searchText)
                            .padding(8)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Filter options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(FilterOption.allCases) { option in
                                FilterButton(
                                    title: option.rawValue,
                                    isSelected: selectedFilter == option,
                                    action: {
                                        selectedFilter = option
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                
                // Categories
                VStack(alignment: .leading, spacing: 15) {
                    Text("Categories")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Category.allCases) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        if selectedCategory == category {
                                            selectedCategory = nil
                                        } else {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Attractions section
                VStack(alignment: .leading, spacing: 15) {
                    Text(selectedCategory?.rawValue ?? "All Attractions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Sample attractions - in a real app, you would fetch these from a database
                    ForEach(0..<5) { _ in
                        AttractionCard()
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// Filter button component
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .purple : .primary)
                .cornerRadius(20)
        }
    }
}

// Category button component
struct CategoryButton: View {
    let category: HomeView.Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray6))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .purple : .primary)
                }
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .purple : .primary)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
    }
}

// Attraction card with navigation to detail view
struct AttractionCard: View {
    // This would be a real attraction in your final app
    let attraction = Attraction.sample
    
    var body: some View {
        NavigationLink(destination: AttractionDetailView(attraction: attraction)) {
            VStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(attraction.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", attraction.rating))
                            .foregroundColor(.primary)
                        Text("(\(attraction.reviewCount) reviews)")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Spacer()
                        Text("2.5 km")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(attraction.category) • \(attraction.subcategory)")
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
        }
    }
}
