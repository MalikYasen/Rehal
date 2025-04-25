import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .topRated
    @State private var selectedCategory: Category? = nil
    @EnvironmentObject var attractionViewModel: AttractionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                                            Task {
                                                await attractionViewModel.fetchAttractions()
                                            }
                                        } else {
                                            selectedCategory = category
                                            Task {
                                                await attractionViewModel.fetchAttractions(category: category.rawValue)
                                            }
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
                    
                    if attractionViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let error = attractionViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else if attractionViewModel.attractions.isEmpty {
                        Text("No attractions found")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        // Filter attractions based on search text
                        let filteredAttractions = searchText.isEmpty ?
                            attractionViewModel.attractions :
                            attractionViewModel.attractions.filter {
                                $0.name.localizedCaseInsensitiveContains(searchText) ||
                                $0.category.localizedCaseInsensitiveContains(searchText) ||
                                ($0.subcategory ?? "").localizedCaseInsensitiveContains(searchText)
                            }
                        
                        ForEach(filteredAttractions) { attraction in
                            AttractionCard(attraction: attraction)
                        }
                    }
                }
            }
            .padding(.vertical)
            .onAppear {
                Task {
                    await attractionViewModel.fetchAttractions()
                    
                    if let userId = authViewModel.session?.user.id {
                        await attractionViewModel.fetchFavorites(for: userId)
                    }
                }
            }
        }
    }
}
