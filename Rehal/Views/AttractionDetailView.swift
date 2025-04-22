//
//  AttractionDetailView.swift
//  Rehal
//
//  Created by Malik Yaseen on 19/04/2025.
//
// AttractionDetailView.swift
import SwiftUI
import MapKit

struct AttractionDetailView: View {
    let attraction: Attraction
    @State private var selectedImageIndex = 0
    @State private var showFullDescription = false
    @State private var region: MKCoordinateRegion
    @State private var showDirections = false
    @Environment(\.presentationMode) var presentationMode
    
    // Define the custom purple color (same as login page)
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    init(attraction: Attraction) {
        self.attraction = attraction
        
        // Initialize the map region centered on the attraction
        _region = State(initialValue: MKCoordinateRegion(
            center: attraction.location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image gallery with page indicator
                ZStack(alignment: .bottom) {
                    // Placeholder image (replace with actual image loading)
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<attraction.imageURLs.count, id: \.self) { index in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 250)
                    
                    // Back button
                    VStack {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            
                            Spacer()
                            
                            Button(action: {
                                // Add to favorites action
                            }) {
                                Image(systemName: "heart")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                        
                        // Page indicator
                        HStack(spacing: 8) {
                            ForEach(0..<attraction.imageURLs.count, id: \.self) { index in
                                Circle()
                                    .fill(selectedImageIndex == index ? logoPurple : Color.white)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .frame(height: 250)
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 20) {
                    // Title and rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text(attraction.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            // Category
                            Text(attraction.category)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            Text(attraction.subcategory)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            // Price level
                            Text(String(repeating: "$", count: attraction.priceLevel))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            // Rating
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                
                                Text(String(format: "%.1f", attraction.rating))
                                    .fontWeight(.semibold)
                                
                                Text("(\(attraction.reviewCount) reviews)")
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Open/Closed status
                            if let todayHours = attraction.workingHours.first(where: { $0.isCurrentlyOpen }) {
                                Text("Open Now")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                            } else {
                                Text("Closed")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Description
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
                    
                    Divider()
                    
                    // Location and map
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                        
                        Text(attraction.address)
                            .font(.subheadline)
                        
                        // Map
                        Map(coordinateRegion: $region, annotationItems: [attraction]) { place in
                            MapMarker(coordinate: place.location, tint: logoPurple)
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
                    
                    Divider()
                    
                    // Working hours
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Working Hours")
                            .font(.headline)
                        
                        ForEach(attraction.workingHours) { hours in
                            HStack {
                                Text(hours.day)
                                    .frame(width: 100, alignment: .leading)
                                
                                Spacer()
                                
                                if hours.isOpen {
                                    Text("\(hours.open) - \(hours.close)")
                                } else {
                                    Text("Closed")
                                        .foregroundColor(.red)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // Contact information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact")
                            .font(.headline)
                        
                        if let phone = attraction.contactInfo.phone {
                            Button(action: {
                                let tel = "tel://\(phone.replacingOccurrences(of: " ", with: ""))"
                                if let url = URL(string: tel), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .frame(width: 24)
                                    Text(phone)
                                    Spacer()
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        
                        if let website = attraction.contactInfo.website {
                            Button(action: {
                                if UIApplication.shared.canOpenURL(website) {
                                    UIApplication.shared.open(website)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .frame(width: 24)
                                    Text(website.host ?? "Website")
                                    Spacer()
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        
                        if let email = attraction.contactInfo.email {
                            Button(action: {
                                let mailto = "mailto:\(email)"
                                if let url = URL(string: mailto), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .frame(width: 24)
                                    Text(email)
                                    Spacer()
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Reviews
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Reviews")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: AllReviewsView(attraction: attraction)) {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(logoPurple)
                            }
                        }
                        
                        // Review summary
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text(String(format: "%.1f", attraction.rating))
                                    .font(.system(size: 36, weight: .bold))
                                
                                // Star rating
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= Int(attraction.rating) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 12))
                                    }
                                }
                                
                                Text("\(attraction.reviewCount) reviews")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Divider()
                                .frame(height: 60)
                            
                            // Rating bars (simplified)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach((1...5).reversed(), id: \.self) { rating in
                                    HStack(spacing: 8) {
                                        Text("\(rating)")
                                            .font(.caption)
                                            .frame(width: 8)
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 6)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.yellow)
                                                    .frame(width: rating == 5 ? 70 : (rating == 4 ? 50 : (rating == 3 ? 30 : (rating == 2 ? 15 : 5))), height: 6),
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
                        
                        // Sample reviews
                        ForEach(attraction.reviews.prefix(2)) { review in
                            ReviewRow(review: review)
                        }
                        
                        // Write review button
                        Button(action: {
                            // Action to write a review
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
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .sheet(isPresented: $showDirections) {
            DirectionsView(destination: attraction.location, name: attraction.name)
        }
    }
}

// Review row component
struct ReviewRow: View {
    let review: Attraction.Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    Text(review.userName)
                        .font(.headline)
                    
                    HStack {
                        // Star rating
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                        
                        Spacer()
                        
                        // Date
                        Text(review.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Text(review.comment)
                .font(.subheadline)
            
            // Review images if any
            if let images = review.images, !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                }
            }
            
            Divider()
        }
    }
}

// All reviews view
struct AllReviewsView: View {
    let attraction: Attraction
    @Environment(\.presentationMode) var presentationMode
    
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
                ForEach(attraction.reviews) { review in
                    ReviewRow(review: review)
                        .padding(.horizontal)
                }
            }
        }
        .navigationBarHidden(true)
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
            Map(coordinateRegion: $region, annotationItems: [MapLocation(id: "destination", coordinate: destination)]) { location in
                MapMarker(coordinate: location.coordinate, tint: .red)
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

struct AttractionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AttractionDetailView(attraction: Attraction.sample)
    }
}
