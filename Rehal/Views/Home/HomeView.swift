import SwiftUI
import Combine

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedCategory: Category? = nil
    @State private var showLocationPermissionAlert = false
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Enhanced category enum with better organization
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
            case .beaches: return "water.waves"
            case .shopping: return "bag"
            case .entertainment: return "ticket"
            }
        }
        
        var color: Color {
            switch self {
            case .restaurants: return .orange
            case .historical: return .blue
            case .beaches: return .teal
            case .shopping: return .purple
            case .entertainment: return .pink
            }
        }
    }
    
    // Theme color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with search
                    VStack(spacing: 16) {
                        // App title
                        HStack {
                            Text("Explore Bahrain")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                // Refresh attractions
                                Task {
                                    await attractionViewModel.fetchAttractions()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search attractions", text: $searchText)
                                .onChange(of: searchText) { newValue in
                                    // Debounce search
                                    if !newValue.isEmpty && newValue.count > 2 {
                                        Task {
                                            await attractionViewModel.searchAttractions(query: newValue)
                                        }
                                    } else if newValue.isEmpty {
                                        Task {
                                            await attractionViewModel.fetchAttractions(
                                                category: selectedCategory?.rawValue
                                            )
                                        }
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    Task {
                                        await attractionViewModel.fetchAttractions(
                                            category: selectedCategory?.rawValue
                                        )
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Categories section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Category chips in a flow layout
                        FlowLayout(spacing: 10) {
                            ForEach(Category.allCases) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        if selectedCategory == category {
                                            selectedCategory = nil
                                            Task {
                                                await attractionViewModel.fetchAttractions()
                                            }
                                        } else {
                                            selectedCategory = category
                                            Task {
                                                await attractionViewModel.fetchAttractions(
                                                    category: category.rawValue
                                                )
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Attractions grid
                    VStack(alignment: .leading, spacing: 16) {
                        // Section header with dynamic title
                        HStack {
                            Text(sectionTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if attractionViewModel.isLoading {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal)
                        
                        if let error = attractionViewModel.error {
                            // Error view
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                
                                Button("Try Again") {
                                    Task {
                                        await attractionViewModel.fetchAttractions(
                                            category: selectedCategory?.rawValue
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(logoPurple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else if attractionViewModel.attractions.isEmpty {
                            // Empty state view
                            VStack(spacing: 16) {
                                Image(systemName: "map")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No attractions found")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Text("Try a different category or search term")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            // Attractions grid layout
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(attractionViewModel.attractions) { attraction in
                                    NavigationLink(destination: AttractionDetailView(attraction: attraction)) {
                                        AttractionCard(attraction: attraction)
                                            .frame(height: 220)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Debug information
//                    #if DEBUG
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Debug Info")
//                            .font(.headline)
//                        
//                        Text("Attraction count: \(attractionViewModel.attractions.count)")
//                        Text("Selected category: \(selectedCategory?.rawValue ?? "None")")
//                        Text("User logged in: \(authViewModel.isAuthenticated ? "Yes" : "No")")
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    #endif
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    // Double check if we have attractions loaded
                    if attractionViewModel.attractions.isEmpty {
                        await attractionViewModel.fetchAttractions()
                    }
                    
                    if let userId = authViewModel.session?.user.id {
                        await attractionViewModel.fetchFavorites(for: userId)
                    }
                }
            }
            .refreshable {
                await attractionViewModel.fetchAttractions(
                    category: selectedCategory?.rawValue
                )
            }
        }
    }
    
    // Dynamic section title based on selection
    var sectionTitle: String {
        if !searchText.isEmpty {
            return "Search Results"
        } else if let category = selectedCategory {
            return category.rawValue
        } else {
            return "Featured Attractions"
        }
    }
}

// Custom flow layout for better category display
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        
        var height: CGFloat = 0
        var width: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if rowWidth + viewSize.width > containerWidth {
                // Start a new row
                width = max(width, rowWidth)
                height += rowHeight + spacing
                rowWidth = viewSize.width
                rowHeight = viewSize.height
            } else {
                // Add to the current row
                rowWidth += viewSize.width + (rowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, viewSize.height)
            }
        }
        
        // Account for the last row
        width = max(width, rowWidth)
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if rowX + viewSize.width > containerWidth + bounds.minX {
                // Start a new row
                rowX = bounds.minX
                rowY += rowHeight + spacing
                rowHeight = viewSize.height
            } else {
                // Update the row height
                rowHeight = max(rowHeight, viewSize.height)
            }
            
            // Place the view
            view.place(
                at: CGPoint(x: rowX, y: rowY),
                proposal: ProposedViewSize(viewSize)
            )
            
            // Update x position for the next view
            rowX += viewSize.width + spacing
        }
    }
}

// Enhanced category chip design
struct CategoryChip: View {
    let category: HomeView.Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected
                ? category.color.opacity(0.15)
                : Color(.systemGray6)
            )
            .foregroundColor(
                isSelected
                ? category.color
                : .primary
            )
            .cornerRadius(20)
        }
    }
}



// Extension for rounded specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
