import Foundation
import Supabase

@MainActor
class AttractionViewModel: ObservableObject {
    @Published var attractions: [Attraction] = []
    @Published var favoriteAttractions: [Attraction] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchQuery: String = ""
    @Published var selectedCategory: String?
    @Published var attractionRatings: [UUID: Double] = [:]
    
    public let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        print("AttractionViewModel initialized")
    }
    
    func fetchAttractions(category: String? = nil) async {
        isLoading = true
        error = nil
        print("Fetching attractions, category: \(category ?? "all")")
        
        do {
            var query = supabase.from("attractions").select()
            
            if let category = category {
                query = query.eq("category", value: category)
            }
            
            let response = try await query.execute()
            print("Fetch response received")
            
            // Process the response
            processResponse(response)
            
            isLoading = false
        } catch {
            print("Error fetching attractions: \(error)")
            isLoading = false
            self.error = "Failed to fetch attractions: \(error.localizedDescription)"
        }
    }
    
    func searchAttractions(query: String, category: String? = nil) async {
        isLoading = true
        error = nil
        
        do {
            var supabaseQuery = supabase.from("attractions").select()
            
            // Apply filters
            if !query.isEmpty {
                // Search in name, description, category, and subcategory
                supabaseQuery = supabaseQuery.or("name.ilike.%\(query)%,description.ilike.%\(query)%,category.ilike.%\(query)%,subcategory.ilike.%\(query)%")
            }
            
            if let category = category {
                supabaseQuery = supabaseQuery.eq("category", value: category)
            }
            
            let response = try await supabaseQuery.execute()
            
            // Process the response
            processResponse(response)
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Search failed: \(error.localizedDescription)"
        }
    }
    
    // Changed to a more generic method without specific type annotation
    private func processResponse(_ response: Any) {
        // Extract data from the response
        guard let responseDict = response as? [String: Any],
              let data = responseDict["data"] as? [[String: Any]] else {
            self.attractions = []
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var loadedAttractions: [Attraction] = []
        
        for json in data {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json)
                if let attraction = try? decoder.decode(Attraction.self, from: jsonData) {
                    loadedAttractions.append(attraction)
                }
            } catch {
                print("Error decoding attraction: \(error)")
            }
        }
        
        self.attractions = loadedAttractions
    }
    
    func fetchNearbyAttractions(latitude: Double, longitude: Double, radiusInKm: Double = 5.0) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await supabase.rpc("nearby_attractions", params: [
                "user_lng": longitude,
                "user_lat": latitude,
                "radius_km": radiusInKm
            ]).execute()
            
            // Process the response with the generic method
            processResponse(response)
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to fetch nearby attractions: \(error.localizedDescription)"
            
            // Fallback: Get all attractions and filter locally if server-side filtering fails
            await fetchAttractions()
        }
    }
    
    func fetchFavorites(for userId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // First get the user's favorites
            let favoritesResponse = try await supabase.from("favorites")
                .select("attraction_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // Use the generic method to extract favorite IDs
            guard let responseDict = favoritesResponse as? [String: Any],
                  let favoritesData = responseDict["data"] as? [[String: Any]] else {
                self.favoriteAttractions = []
                isLoading = false
                return
            }
            
            let attractionIds = favoritesData.compactMap { $0["attraction_id"] as? String }
            
            print("Found \(attractionIds.count) favorite attraction IDs")
            
            // If we have favorite attraction IDs, fetch the actual attractions
            if !attractionIds.isEmpty {
                var loadedFavorites: [Attraction] = []
                
                // Fetch attractions in one batch if possible
                let attractionsResponse = try await supabase.from("attractions")
                    .select()
                    .in("id", values: attractionIds)
                    .execute()
                
                // Use the generic method to extract attractions
                guard let responseDict = attractionsResponse as? [String: Any],
                      let attractionsData = responseDict["data"] as? [[String: Any]] else {
                    self.favoriteAttractions = []
                    isLoading = false
                    return
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                for attractionData in attractionsData {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: attractionData)
                        if let attraction = try? decoder.decode(Attraction.self, from: jsonData) {
                            loadedFavorites.append(attraction)
                        }
                    } catch {
                        print("Error decoding favorite attraction: \(error)")
                    }
                }
                
                self.favoriteAttractions = loadedFavorites
                print("Loaded \(loadedFavorites.count) favorite attractions")
            } else {
                self.favoriteAttractions = []
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to fetch favorites: \(error.localizedDescription)"
            print("Error fetching favorites: \(error)")
        }
    }
    
    func addToFavorites(attractionId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await supabase.from("favorites")
                .insert([
                    "user_id": userId.uuidString,
                    "attraction_id": attractionId.uuidString
                ])
                .execute()
            
            isLoading = false
            
            // Update local favorites list
            if let attraction = attractions.first(where: { $0.id == attractionId }),
               !favoriteAttractions.contains(where: { $0.id == attractionId }) {
                favoriteAttractions.append(attraction)
            }
            
            return true
        } catch {
            isLoading = false
            self.error = "Failed to add to favorites: \(error.localizedDescription)"
            print("Error adding to favorites: \(error)")
            return false
        }
    }
    
    func removeFromFavorites(attractionId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await supabase.from("favorites")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("attraction_id", value: attractionId.uuidString)
                .execute()
            
            isLoading = false
            
            // Update local favorites list
            favoriteAttractions.removeAll(where: { $0.id == attractionId })
            
            return true
        } catch {
            isLoading = false
            self.error = "Failed to remove from favorites: \(error.localizedDescription)"
            print("Error removing from favorites: \(error)")
            return false
        }
    }
    
    func isFavorite(attractionId: UUID) -> Bool {
        return favoriteAttractions.contains(where: { $0.id == attractionId })
    }
    
    // Calculate and cache ratings for attractions
    func updateRatings(reviews: [Review]) {
        var ratingsByAttraction: [UUID: [Int]] = [:]
        
        // Group reviews by attraction
        for review in reviews {
            if ratingsByAttraction[review.attractionId] == nil {
                ratingsByAttraction[review.attractionId] = []
            }
            ratingsByAttraction[review.attractionId]?.append(review.rating)
        }
        
        // Calculate average ratings
        for (attractionId, ratings) in ratingsByAttraction {
            if !ratings.isEmpty {
                let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
                attractionRatings[attractionId] = average
            }
        }
    }
    
    // Get average rating for an attraction
    func averageRating(for attractionId: UUID) -> Double {
        return attractionRatings[attractionId] ?? 0.0
    }
}
