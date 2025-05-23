import SwiftUI
import MapKit

struct AttractionDetailView: View {
    let attraction: Attraction
    @State private var selectedImageIndex = 0
    @State private var showFullDescription = false
    @State private var region: MKCoordinateRegion
    @State private var showDirections = false
    @State private var showAddReviewSheet = false
    @State private var isFavorite: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var hasAppeared = false
    @State private var appearanceCount = 0  // Track how many times the view has appeared
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var attractionViewModel: AttractionViewModel
    @EnvironmentObject private var reviewViewModel: ReviewViewModel
    
    // Define the custom purple color
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    init(attraction: Attraction) {
        self.attraction = attraction
        
        // Initialize the map region centered on the attraction or default to Manama, Bahrain
        if let location = attraction.location {
            _region = State(initialValue: MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            // Default to Manama, Bahrain
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 26.2235, longitude: 50.5876),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let topSafeArea = geometry.safeAreaInsets.top
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Image gallery with page indicator
                    ZStack(alignment: .top) {
                        imageGallery
                        controlsOverlay(topSafeArea: topSafeArea)
                    }
                    
                    // Main content
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        Divider()
                        descriptionSection
                        Divider()
                        locationSection
                        Divider()
                        reviewsSection
                    }
                    .padding()
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .sheet(isPresented: $showDirections) {
                if let location = attraction.location {
                    DirectionsView(destination: location, name: attraction.name)
                }
            }
            .sheet(isPresented: $showAddReviewSheet) {
                if let userId = authViewModel.session?.user.id {
                    AddReviewView(attraction: attraction, userId: userId)
                        .environmentObject(reviewViewModel)
                }
            }
            .onAppear {
                print("AttractionDetailView appeared for \(attraction.name)")
                print("Attraction ID: \(attraction.id)")
                
                // Increment appearance counter
                appearanceCount += 1
                
                // Only set hasAppeared to true after the first appearance to ensure stability
                // Use a longer delay for the first appearance
                if appearanceCount == 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        hasAppeared = true
                        print("AttractionDetailView stable: hasAppeared set to true")
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        hasAppeared = true
                        print("AttractionDetailView subsequent appear: hasAppeared set to true")
                    }
                }
                
                Task {
                    if let userId = authViewModel.session?.user.id {
                        print("Checking favorites for user: \(userId)")
                        
                        let favoriteCheck = await checkFavoriteDirectly(userId: userId, attractionId: attraction.id)
                        
                        await MainActor.run {
                            isFavorite = favoriteCheck
                        }
                        
                        await attractionViewModel.fetchFavorites(for: userId)
                    }
                    
                    await reviewViewModel.fetchReviews(for: attraction.id)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var imageGallery: some View {
        Group {
            if let images = attraction.images, !images.isEmpty {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<images.count, id: \.self) { index in
                        AsyncImage(url: getProperImageURL(images[index])) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 250)
                
                // Page indicator at the bottom
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0..<(attraction.images?.count ?? 0), id: \.self) { index in
                            Circle()
                                .fill(selectedImageIndex == index ? logoPurple : Color.white)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .frame(height: 250)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
    }
    
    private func controlsOverlay(topSafeArea: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Add padding for the safe area
            Spacer().frame(height: topSafeArea)
            
            // Gradient for better button visibility
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.4), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)
            .overlay(
                HStack {
                    Button(action: {
                        // Only dismiss if the view has fully appeared
                        if hasAppeared && appearanceCount >= 1 {
                            print("Dismissing AttractionDetailView for \(attraction.name)")
                            dismiss()
                        } else {
                            print("Attempted to dismiss but view is not ready yet")
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    if let userId = authViewModel.session?.user.id {
                        Button(action: {
                            toggleFavorite(userId: userId)
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 8)
            )
            
            Spacer()
        }
        .frame(height: 250)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(attraction.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                // Category
                Text(attraction.category)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let subcategory = attraction.subcategory {
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(subcategory)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Price level
                if let priceLevel = attraction.priceLevel {
                    Text(String(repeating: "$", count: priceLevel))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // We'll display average rating from reviews
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", calculateAverageRating()))
                        .fontWeight(.semibold)
                    
                    Text("(\(reviewViewModel.reviews.count) reviews)")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(attraction.description)
                .font(.body)
                .lineLimit(showFullDescription ? nil : 3)
            
            Button(action: {
                showFullDescription.toggle()
            }) {
                Text(showFullDescription ? "Show Less" : "Read More")
                    .font(.subheadline)
                    .foregroundColor(logoPurple)
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            
            if let address = attraction.address {
                Text(address)
                    .font(.subheadline)
            }
            
            // Map
            if let location = attraction.location {
                Map {
                    Marker(coordinate: location, label: {
                        Text(attraction.name)
                    })
                    .tint(logoPurple)
                }
                .frame(height: 200)
                .cornerRadius(12)
                
                // Directions button
                Button(action: {
                    showDirections = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Get Directions")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(logoPurple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reviews")
                    .font(.headline)
                
                Spacer()
                
                if reviewViewModel.reviews.count > 2 {
                    NavigationLink(destination: AllReviewsView(attraction: attraction)) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(logoPurple)
                    }
                }
            }
            
            // Review summary
            if !reviewViewModel.reviews.isEmpty {
                reviewSummaryView
            }
            
            // Reviews display
            if reviewViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if reviewViewModel.reviews.isEmpty {
                Text("No reviews yet. Be the first to review!")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Display top 2 reviews
                ForEach(reviewViewModel.reviews.prefix(2)) { review in
                    ReviewRow(reviewId: review.id, reviewViewModel: reviewViewModel)
                }
            }
            
            // Write review button
            reviewActionButton
        }
    }
    
    private var reviewSummaryView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(String(format: "%.1f", calculateAverageRating()))
                    .font(.system(size: 36, weight: .bold))
                
                // Star rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(calculateAverageRating()) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }
                
                Text("\(reviewViewModel.reviews.count) reviews")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
                .frame(height: 60)
            
            // Rating bars (showing distribution)
            VStack(alignment: .leading, spacing: 6) {
                ForEach((1...5).reversed(), id: \.self) { rating in
                    HStack(spacing: 8) {
                        Text("\(rating)")
                            .font(.caption)
                            .frame(width: 8)
                        
                        let percentage = calculateRatingPercentage(for: rating)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 6)
                            .overlay(
                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(width: 100 * percentage, height: 6),
                                alignment: .leading
                            )
                            .cornerRadius(3)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var reviewActionButton: some View {
        Group {
            if authViewModel.isAuthenticated {
                Button(action: {
                    showAddReviewSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Write a Review")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            } else {
                NavigationLink(destination: LoginView()) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Log in to Write a Review")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Checks if an attraction is a favorite directly from the database
    private func checkFavoriteDirectly(userId: UUID, attractionId: UUID) async -> Bool {
        // Use the improved function in the ViewModel instead of direct DB access
        return await attractionViewModel.checkIfFavorite(attractionId: attractionId, userId: userId)
    }
    
    /// Toggles the favorite status of an attraction
    private func toggleFavorite(userId: UUID) {
        print("Toggle favorite button pressed for \(attraction.name)")
        
        // Immediately show UI change for better responsiveness
        isFavorite.toggle()
        
        Task {
            var success = false
            
            if !isFavorite {
                // We just toggled to not favorite, so remove it
                print("Removing from favorites: \(attraction.id)")
                success = await attractionViewModel.removeFromFavorites(
                    attractionId: attraction.id,
                    userId: userId
                )
                
                if !success {
                    // Revert UI change if operation failed
                    await MainActor.run {
                        print("Failed to remove from favorites, reverting UI")
                        isFavorite = true
                    }
                } else {
                    print("Successfully removed from favorites")
                }
            } else {
                // We just toggled to favorite, so add it
                print("Adding to favorites: \(attraction.id)")
                success = await attractionViewModel.addToFavorites(
                    attractionId: attraction.id,
                    userId: userId
                )
                
                if !success {
                    // Revert UI change if operation failed
                    await MainActor.run {
                        print("Failed to add to favorites, reverting UI")
                        isFavorite = false
                    }
                } else {
                    print("Successfully added to favorites")
                }
            }
            
            // Always refresh the favorites collection to ensure UI consistency across the app
            if success {
                await attractionViewModel.fetchFavorites(for: userId)
            }
        }
    }
    
    /// Calculates the average rating for an attraction
    private func calculateAverageRating() -> Double {
        if reviewViewModel.reviews.isEmpty {
            return 0.0
        }
        
        let sum = reviewViewModel.reviews.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(reviewViewModel.reviews.count)
    }
    
    /// Calculates the percentage of reviews with a specific rating
    private func calculateRatingPercentage(for rating: Int) -> Double {
        if reviewViewModel.reviews.isEmpty {
            return 0.0
        }
        
        let count = reviewViewModel.reviews.filter { $0.rating == rating }.count
        return Double(count) / Double(reviewViewModel.reviews.count)
    }
    
    /// Ensures image URLs are properly formatted
    private func getProperImageURL(_ urlString: String) -> URL? {
        if urlString.hasPrefix("http") {
            return URL(string: urlString)
        } else {
            // Use the exact path to your Supabase storage
            return URL(string: "https://vulhxauybqrvunqkazty.supabase.co/storage/v1/object/public/rehal-storage/attractions/\(urlString)")
        }
    }
}

// Review row component
struct ReviewRow: View {
    // Use a binding instead of state to keep it updated
    let reviewId: UUID
    @ObservedObject var reviewViewModel: ReviewViewModel
    
    init(reviewId: UUID, reviewViewModel: ReviewViewModel) {
        self.reviewId = reviewId
        self.reviewViewModel = reviewViewModel
    }
    
    // Computed property to get the current review
    private var review: Review? {
        reviewViewModel.reviews.first(where: { $0.id == reviewId })
    }
    
    // Supabase storage base URL
    private let storageBaseUrl = "https://vulhxauybqrvunqkazty.supabase.co/storage/v1/object/public/rehal-storage/reviews/"
    
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
        VStack(alignment: .leading, spacing: 8) {
            if let review = review {
                HStack {
                    // User image (placeholder)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // User name with debugging info
                        if let userName = review.userName {
                            Text(userName)
                                .font(.headline)
                                .id("username-\(review.id)") // Force refresh when username changes
                        } else {
                            Text("User")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            // Star rating
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= review.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                            
                            Text(review.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if let comment = review.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.body)
                        .padding(.top, 4)
                }
                
                // Display review images if available
                if let images = review.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(images, id: \.self) { imageUrl in
                                if let url = getFullImageUrl(imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 120, height: 80)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                                .frame(width: 120, height: 80)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                Text("Review not found")
                    .foregroundColor(.gray)
            }
        }
    }
}

// All reviews view
struct AllReviewsView: View {
    let attraction: Attraction
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var reviewViewModel: ReviewViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    
                    Text("All Reviews")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding()
                
                // Reviews
                if reviewViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if reviewViewModel.reviews.isEmpty {
                    Text("No reviews yet")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    // Force view to update when reviews change
                    ForEach(reviewViewModel.reviews) { review in
                        ReviewRow(reviewId: review.id, reviewViewModel: reviewViewModel)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await reviewViewModel.fetchReviews(for: attraction.id)
            }
        }
    }
}

// Directions view
struct DirectionsView: View {
    let destination: CLLocationCoordinate2D
    let name: String
    @State private var region: MKCoordinateRegion
    @State private var route: MKRoute?
    @State private var isLoadingRoute = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    init(destination: CLLocationCoordinate2D, name: String) {
        self.destination = destination
        self.name = name
        
        // Initialize the map region centered on the destination
        _region = State(initialValue: MKCoordinateRegion(
            center: destination,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .padding()
                }
                
                Spacer()
                
                Text("Directions to \(name)")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                // Placeholder to balance the layout
                Image(systemName: "xmark")
                    .font(.title2)
                    .padding()
                    .opacity(0)
            }
            
            // Map with route
            Map {
                Marker(coordinate: destination, label: {
                    Text(name)
                })
                .tint(.red)
                
                if let route = route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 3)
                }
            }
            .edgesIgnoringSafeArea(.horizontal)
            
            // Loading indicator or error message
            if isLoadingRoute {
                ProgressView("Calculating route...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Open in Maps button
            Button(action: {
                openInMaps()
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Open in Maps")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
        }
        .onAppear {
            calculateRoute()
        }
    }
    
    // Helper struct for map annotation
    struct MapLocation: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
    }
    
    // Calculate route from current location to destination
    private func calculateRoute() {
        isLoadingRoute = true
        errorMessage = nil
        
        // In a real app, you would get the user's current location
        // For now, we'll use a hardcoded starting point
        let startCoordinate = CLLocationCoordinate2D(latitude: 26.2235, longitude: 50.5876) // Example: Manama
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            isLoadingRoute = false
            
            if let error = error {
                errorMessage = "Error calculating route: \(error.localizedDescription)"
                return
            }
            
            guard let route = response?.routes.first else {
                errorMessage = "No route found"
                return
            }
            
            self.route = route
            
            // Adjust the region to show the route
            let rect = route.polyline.boundingMapRect
            region = MKCoordinateRegion(rect)
        }
    }
    
    // Open Apple Maps with directions
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        mapItem.name = name
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// Add Review View
struct AddReviewView: View {
    let attraction: Attraction
    let userId: UUID
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var uploadedImageUrl: String?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var reviewViewModel: ReviewViewModel
    @EnvironmentObject var storageService: StorageService
    
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rating")) {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.title)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
                
                Section(header: Text("Review")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
                
                // Image upload section
                Section(header: Text("Add Photo")) {
                    if let selectedImage = selectedImage {
                        HStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button(action: {
                                self.selectedImage = nil
                                self.uploadedImageUrl = nil
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Add Photo")
                            }
                        }
                    }
                }
                
                if storageService.isUploading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Uploading photo...")
                            Spacer()
                        }
                    }
                }
                
                if let error = reviewViewModel.error ?? storageService.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        submitReview()
                    }) {
                        if reviewViewModel.isLoading || storageService.isUploading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Submit Review")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(logoPurple)
                        }
                    }
                    .disabled(rating == 0 || reviewViewModel.isLoading || storageService.isUploading)
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func submitReview() {
        Task {
            // First upload image if selected
            if let image = selectedImage {
                uploadedImageUrl = await storageService.uploadImage(
                    image,
                    path: "reviews/\(attraction.id.uuidString)"
                )
            }
            
            // Then submit review with image URL if available
            var imageUrls: [String]? = nil
            if let uploadedUrl = uploadedImageUrl {
                imageUrls = [uploadedUrl]
            }
            
            let success = await reviewViewModel.addReview(
                attractionId: attraction.id,
                userId: userId,
                rating: rating,
                comment: comment,
                images: imageUrls
            )
            
            if success {
                await reviewViewModel.fetchReviews(for: attraction.id)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Image Picker for selecting photos
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
