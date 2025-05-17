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
            
            // Execute the query
            let response = try await query.execute()
            print("Fetch response received")
            
            // Process the response with the generic method
            processResponse(response)
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to fetch attractions: \(error.localizedDescription)"
        }
    }
    
    func searchAttractions(query: String, category: String? = nil) async {
        isLoading = true
        error = nil
        print("Searching attractions with query: \(query), category: \(category ?? "all")")
        
        do {
            // Start with the base query
            var queryBuilder = supabase.from("attractions").select()
            
            // Apply search filter using the ILIKE operator for each column separately
            if !query.isEmpty {
                let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
                let searchPattern = "%\(searchTerm)%"
                
                queryBuilder = queryBuilder.or(
                    "name.ilike.\(searchPattern),description.ilike.\(searchPattern),category.ilike.\(searchPattern),subcategory.ilike.\(searchPattern)"
                )
            }
            
            // Apply category filter if specified
            if let category = category {
                queryBuilder = queryBuilder.eq("category", value: category)
            }
            
            // Execute the query
            let response = try await queryBuilder.execute()
            print("Search response received")
            
            // Process the response with the generic method
            processResponse(response)
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to search attractions: \(error.localizedDescription)"
        }
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
        print("Fetching favorites for user: \(userId)")
        
        do {
            // Get the user's favorite attraction IDs
            let response = try await supabase.from("favorites")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // Get the data from response
            let data = response.data
            print("Favorites data size: \(data.count) bytes")
            
            do {
                // Convert the data to a structured format we can work with
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let attractionIds = jsonArray.compactMap { $0["attraction_id"] as? String }
                    
                    print("Found \(attractionIds.count) favorite attraction IDs")
                    
                    // If we have favorite attraction IDs, fetch the actual attractions
                    if !attractionIds.isEmpty {
                        // Fetch attractions in one batch, explicitly select all fields including images
                        let attractionsResponse = try await supabase.from("attractions")
                            .select("id, name, description, category, subcategory, address, latitude, longitude, images, price_level, created_at, updated_at")
                            .in("id", values: attractionIds)
                            .execute()
                        
                        // Get the data from response
                        let attractionsData = attractionsResponse.data
                        print("Favorites attractions data size: \(attractionsData.count) bytes")
                        
                        if let jsonString = String(data: attractionsData, encoding: .utf8) {
                            print("Favorites JSON (first 100 chars): \(jsonString.prefix(100))")
                        }
                        
                        // Try to decode the attractions data
                        do {
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            
                            let favorites = try decoder.decode([Attraction].self, from: attractionsData)
                            await MainActor.run {
                                self.favoriteAttractions = favorites
                            }
                            print("Loaded \(favorites.count) favorite attractions")
                            for (i, fav) in favorites.prefix(2).enumerated() {
                                print("Favorite \(i): \(fav.name), images: \(fav.images?.count ?? 0)")
                            }
                        } catch {
                            print("Error decoding favorites: \(error)")
                            
                            // Fallback: manual parsing
                            if let jsonArray = try? JSONSerialization.jsonObject(with: attractionsData) as? [[String: Any]] {
                                var loadedFavorites: [Attraction] = []
                                let fallbackDecoder = JSONDecoder()
                                fallbackDecoder.dateDecodingStrategy = .iso8601
                                
                                for (index, json) in jsonArray.enumerated() {
                                    do {
                                        // Print first attraction for debugging
                                        if index == 0 {
                                            print("First favorite attraction JSON: \(json)")
                                            if let images = json["images"] {
                                                print("Images found: \(images)")
                                            } else {
                                                print("No images field found!")
                                            }
                                        }
                                        
                                        let jsonData = try JSONSerialization.data(withJSONObject: json)
                                        let attraction = try fallbackDecoder.decode(Attraction.self, from: jsonData)
                                        loadedFavorites.append(attraction)
                                        
                                        // Print debug info for first attraction
                                        if index == 0 {
                                            print("Decoded attraction: \(attraction.name), images: \(attraction.images?.count ?? 0)")
                                        }
                                    } catch {
                                        print("Error decoding favorite attraction at index \(index): \(error)")
                                    }
                                }
                                
                                await MainActor.run {
                                    self.favoriteAttractions = loadedFavorites
                                }
                                print("Manually processed \(loadedFavorites.count) favorite attractions")
                            }
                        }
                    } else {
                        await MainActor.run {
                            self.favoriteAttractions = []
                        }
                    }
                } else {
                    print("Failed to parse favorites data as JSON array")
                    await MainActor.run {
                        self.favoriteAttractions = []
                    }
                }
            } catch {
                print("Error processing favorites: \(error)")
                await MainActor.run {
                    self.favoriteAttractions = []
                }
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
            // First check if this favorite already exists using our improved checkIfFavorite method
            let alreadyFavorite = await checkIfFavorite(attractionId: attractionId, userId: userId)
            
            if alreadyFavorite {
                // It's already a favorite - this is success
                print("Already in favorites")
                
                // Update local list if needed
                if let attraction = attractions.first(where: { $0.id == attractionId }),
                   !favoriteAttractions.contains(where: { $0.id == attractionId }) {
                    favoriteAttractions.append(attraction)
                }
                
                isLoading = false
                return true
            }
            
            // If we get here, the favorite doesn't exist yet, so we create it with a generated UUID
            let favoriteId = UUID()
            let jsonData = try JSONSerialization.data(withJSONObject: [
                "id": favoriteId.uuidString,
                "user_id": userId.uuidString,
                "attraction_id": attractionId.uuidString
            ])
            
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            try await supabase.from("favorites")
                .insert(jsonString)
                .execute()
            
            // Update local list
            if let attraction = attractions.first(where: { $0.id == attractionId }),
               !favoriteAttractions.contains(where: { $0.id == attractionId }) {
                favoriteAttractions.append(attraction)
            }
            
            print("Successfully added to favorites")
            isLoading = false
            return true
        } catch {
            // Check if it's a duplicate key error
            if error.localizedDescription.contains("duplicate key") ||
               error.localizedDescription.contains("unique constraint") {
                // It's already a favorite - this is actually success
                print("Already in favorites (caught constraint violation)")
                
                // Update local list if needed
                if let attraction = attractions.first(where: { $0.id == attractionId }),
                   !favoriteAttractions.contains(where: { $0.id == attractionId }) {
                    favoriteAttractions.append(attraction)
                }
                
                isLoading = false
                return true
            }
            
            // Some other error
            print("Error adding to favorites: \(error)")
            isLoading = false
            self.error = "Failed to add to favorites: \(error.localizedDescription)"
            return false
        }
    }
    
    func removeFromFavorites(attractionId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        error = nil
        print("Removing from favorites: attraction \(attractionId) for user \(userId)")
        
        do {
            // Use proper JSON format with string values for UUIDs
            try await supabase.from("favorites")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("attraction_id", value: attractionId.uuidString)
                .execute()
            
            print("Successfully removed from favorites")
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
    
    func checkIfFavorite(attractionId: UUID, userId: UUID) async -> Bool {
        print("Checking if attraction \(attractionId) is a favorite for user \(userId)")
        
        // First check local cache
        if favoriteAttractions.contains(where: { $0.id == attractionId }) {
            print("Found in local favorites cache")
            return true
        }
        
        // If not found locally, check with the server
        do {
            let response = try await supabase.from("favorites")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("attraction_id", value: attractionId.uuidString)
                .execute()
            
            // Get the data from response
            let data = response.data
            
            // Try to parse the response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Favorite check response: \(jsonString)")
                
                // If the JSON contains the attraction ID, it's likely a favorite
                // This is a simple check that works regardless of the exact response format
                if jsonString.contains(attractionId.uuidString.lowercased()) {
                    print("Found favorite entry on server (string contains ID)")
                    return true
                }
            }
            
            // Try the generic approach to parse data
            if (data.count > 0) {
                do {
                    // Try to convert the data to a dictionary or array
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    // Check if we have any results
                    if let jsonArray = jsonObject as? [[String: Any]], !jsonArray.isEmpty {
                        print("Found favorite entry on server (array of dictionaries)")
                        return true
                    } else if let jsonDict = jsonObject as? [String: Any], !jsonDict.isEmpty {
                        print("Found favorite entry on server (dictionary)")
                        return true
                    }
                } catch {
                    print("Error parsing favorite check response: \(error)")
                    // Continue to the next approach
                }
            }
            
            print("No favorite entry found on server")
            return false
        } catch {
            print("Error checking favorite status: \(error)")
            return false
        }
    }
    
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
    
    // Calculate and return the average rating for an attraction
    func getAverageRating(for attractionId: UUID) -> Double {
        // First check if we have a cached rating
        if let cachedRating = attractionRatings[attractionId] {
            return cachedRating
        }
        
        // Otherwise, default to 0
        return 0.0
    }
    
    // Update the cached rating for an attraction
    func updateRating(for attractionId: UUID, with reviews: [Review]) {
        if reviews.isEmpty {
            attractionRatings[attractionId] = 0.0
            return
        }
        
        let sum = reviews.reduce(0) { $0 + $1.rating }
        let averageRating = Double(sum) / Double(reviews.count)
        
        // Cache the rating
        attractionRatings[attractionId] = averageRating
    }
    
    // Get average rating for an attraction
    func averageRating(for attractionId: UUID) -> Double {
        return attractionRatings[attractionId] ?? 0.0
    }
    
    // Changed to a more generic method without specific type annotation
    private func processResponse(_ response: Any) {
        // Check if we received a PostgrestResponse
        print("Response type: \(type(of: response))")
        
        // Try to extract the data based on the response type
        var dataToProcess: Any?
        
        if let postgrestResponse = response as? PostgrestResponse<Any> {
            // Direct access to data
            dataToProcess = postgrestResponse.data
            print("Successfully extracted data from PostgrestResponse<Any>")
        } else if let postgrestResponseEmpty = response as? PostgrestResponse<()> {
            // This appears to be how valid data comes through in some cases, so just process it normally
            print("Processing PostgrestResponse<()>")
            dataToProcess = postgrestResponseEmpty.data
            print("Data size: \(postgrestResponseEmpty.data.count) bytes")
            
            if let jsonString = String(data: postgrestResponseEmpty.data, encoding: .utf8) {
                print("Data as string: \(jsonString.prefix(100))...")
            }
            
            // Try to parse the data directly
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: postgrestResponseEmpty.data)
                print("Successfully parsed data: \(type(of: jsonObject))")
                
                if let jsonArray = jsonObject as? [[String: Any]] {
                    print("JSON array contains \(jsonArray.count) items")
                    Task {
                        await parseAttractionsManually(jsonArray)
                    }
                    return
                }
            } catch {
                print("Error parsing JSON: \(error)")
                // Continue with other approaches
            }
        } else if let dict = response as? [String: Any], let data = dict["data"] {
            // Dictionary with data key
            dataToProcess = data
            print("Successfully extracted data from dictionary")
        } else {
            // Try to use the response directly
            dataToProcess = response
            print("Using response directly as data")
        }
        
        if let dataToProcess = dataToProcess {
            print("Data to process type: \(type(of: dataToProcess))")
            
            // Special handling for Data objects
            if let dataObj = dataToProcess as? Data {
                do {
                    // Try to parse the data directly
                    let parsedObject = try JSONSerialization.jsonObject(with: dataObj)
                    print("Successfully parsed Data object: \(type(of: parsedObject))")
                    
                    // Try to process it as an array of attractions
                    if let jsonArray = parsedObject as? [[String: Any]] {
                        Task {
                            await parseAttractionsManually(jsonArray)
                        }
                        return
                    }
                    
                    // Recursively process the parsed result if it's not an array
                    processResponse(parsedObject)
                    return
                } catch {
                    print("Error parsing Data object: \(error)")
                }
            }
            
            // Check if dataToProcess is a valid JSON object type before trying to serialize
            if JSONSerialization.isValidJSONObject(dataToProcess) {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dataToProcess)
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let attractions = try decoder.decode([Attraction].self, from: jsonData)
                        
                        // Update the attractions on the main actor
                        Task { @MainActor in
                            self.attractions = attractions
                            self.isLoading = false
                            print("Successfully decoded \(attractions.count) attractions")
                        }
                        return
                    } catch {
                        print("Error decoding attractions: \(error)")
                        // Continue to the manual parsing approach
                    }
                } catch {
                    print("Error serializing to JSON: \(error)")
                }
            } else {
                print("Warning: dataToProcess is not a valid JSON object: \(dataToProcess)")
            }
            
            // Manual approach if the automatic decoding failed
            if let arrayData = dataToProcess as? [[String: Any]] {
                Task {
                    await parseAttractionsManually(arrayData)
                }
            } else if let singleData = dataToProcess as? [String: Any] {
                Task {
                    await parseAttractionsManually([singleData])
                }
            } else {
                print("Unexpected response format or empty data")
                Task { @MainActor in
                    self.attractions = []
                    self.isLoading = false
                }
            }
        } else {
            print("No data found in response")
            Task { @MainActor in
                self.attractions = []
                self.isLoading = false
            }
        }
    }
    
    private func parseAttractionsManually(_ jsonArray: [[String: Any]]) async {
        print("Manually parsing \(jsonArray.count) attractions")
        
        var loadedAttractions: [Attraction] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for (index, json) in jsonArray.enumerated() {
            do {
                // Convert the dictionary to JSON data
                let jsonData = try JSONSerialization.data(withJSONObject: json)
                
                // Try to decode as Attraction
                let attraction = try decoder.decode(Attraction.self, from: jsonData)
                loadedAttractions.append(attraction)
                
                if index == 0 {
                    print("First attraction parsed successfully: \(attraction.name)")
                }
            } catch {
                print("Error decoding attraction at index \(index): \(error)")
                if index == 0 {
                    print("Problem JSON: \(json)")
                }
            }
        }
        
        print("Successfully parsed \(loadedAttractions.count) attractions manually")
        
        // Update on main actor
        await MainActor.run {
            self.attractions = loadedAttractions
            self.isLoading = false
        }
    }
}
