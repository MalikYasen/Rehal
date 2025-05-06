import Foundation
import Supabase

@MainActor
class AttractionViewModel: ObservableObject {
    @Published var attractions: [Attraction] = []
    @Published var favoriteAttractions: [Attraction] = []
    @Published var isLoading = false
    @Published var error: String?
    
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
            
            // Check what we're getting back
            print("Response data type: \(type(of: response.data))")
            print("Response data: \(String(describing: response.data))")
            
            // Handle the response as raw Data
            if let responseData = response.data as? Data {
                do {
                    // Decode the JSON data
                    let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])
                    print("JSON object type: \(type(of: jsonObject))")
                    
                    // Check if it's an array of attractions
                    if let attractionsArray = jsonObject as? [[String: Any]] {
                        print("Found \(attractionsArray.count) attractions in JSON array")
                        
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        var loadedAttractions: [Attraction] = []
                        
                        for (index, json) in attractionsArray.enumerated() {
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: json)
                                if let attraction = try? decoder.decode(Attraction.self, from: jsonData) {
                                    loadedAttractions.append(attraction)
                                    print("Successfully decoded attraction: \(attraction.name)")
                                } else {
                                    print("Failed to decode attraction at index \(index)")
                                }
                            } catch {
                                print("Error processing attraction at index \(index): \(error)")
                            }
                        }
                        
                        self.attractions = loadedAttractions
                        print("Successfully loaded \(loadedAttractions.count) attractions")
                    }
                    // It might be in a nested structure like {"data": [...]}
                    else if let jsonDict = jsonObject as? [String: Any],
                            let attractionsArray = jsonDict["data"] as? [[String: Any]] {
                        print("Found \(attractionsArray.count) attractions in nested data field")
                        
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        var loadedAttractions: [Attraction] = []
                        
                        for (index, json) in attractionsArray.enumerated() {
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: json)
                                if let attraction = try? decoder.decode(Attraction.self, from: jsonData) {
                                    loadedAttractions.append(attraction)
                                    print("Successfully decoded attraction: \(attraction.name)")
                                } else {
                                    print("Failed to decode attraction at index \(index)")
                                }
                            } catch {
                                print("Error processing attraction at index \(index): \(error)")
                            }
                        }
                        
                        self.attractions = loadedAttractions
                        print("Successfully loaded \(loadedAttractions.count) attractions")
                    } else {
                        print("JSON structure not recognized: \(jsonObject)")
                        self.attractions = []
                        self.error = "Data format not recognized"
                    }
                } catch {
                    print("Error parsing JSON data: \(error)")
                    self.attractions = []
                    self.error = "Error parsing response data"
                }
            } else {
                print("Response data is not of type Data")
                self.attractions = []
                self.error = "Unexpected response format"
            }
            
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
            
            if let jsonArray = response.data as? [[String: Any]] {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                var loadedAttractions: [Attraction] = []
                
                for json in jsonArray {
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
            } else {
                self.attractions = []
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Search failed: \(error.localizedDescription)"
        }
    }
    
    func fetchNearbyAttractions(latitude: Double, longitude: Double, radiusInKm: Double = 5.0) async {
        isLoading = true
        error = nil
        
        // Using PostGIS (if available in your Supabase instance) for location-based queries
        // If not, you might need to calculate distances on the client side
        do {
            // This assumes your Supabase has PostGIS enabled and your table has a geo_point column
            // If not, you'll need to fetch all attractions and filter them locally
            let query = """
                SELECT *, 
                ST_Distance(
                    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
                    ST_SetSRID(ST_MakePoint(\(longitude), \(latitude)), 4326)::geography
                ) as distance
                FROM attractions
                WHERE ST_DWithin(
                    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
                    ST_SetSRID(ST_MakePoint(\(longitude), \(latitude)), 4326)::geography,
                    \(radiusInKm * 1000)
                )
                ORDER BY distance
            """
            
            let response = try await supabase.rpc("nearby_attractions", params: [
                "user_lng": longitude,
                "user_lat": latitude,
                "radius_km": radiusInKm
            ]).execute()
            
            if let jsonArray = response.data as? [[String: Any]] {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                var loadedAttractions: [Attraction] = []
                
                for json in jsonArray {
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
            } else {
                self.attractions = []
            }
            
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
            
            var attractionIds: [String] = []
            
            if let favoritesData = favoritesResponse.data as? [[String: Any]] {
                attractionIds = favoritesData.compactMap { $0["attraction_id"] as? String }
            }
            
            // If we have favorite attraction IDs, fetch the actual attractions
            if !attractionIds.isEmpty {
                var loadedFavorites: [Attraction] = []
                
                // Fetch each attraction individually
                for id in attractionIds {
                    let attractionResponse = try await supabase.from("attractions")
                        .select()
                        .eq("id", value: id)
                        .execute()
                    
                    if let attractionData = attractionResponse.data as? [[String: Any]],
                       let firstAttraction = attractionData.first {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let jsonData = try JSONSerialization.data(withJSONObject: firstAttraction)
                        if let attraction = try? decoder.decode(Attraction.self, from: jsonData) {
                            loadedFavorites.append(attraction)
                        }
                    }
                }
                
                self.favoriteAttractions = loadedFavorites
            } else {
                self.favoriteAttractions = []
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to fetch favorites: \(error.localizedDescription)"
        }
    }
    
    func addToFavorites(attractionId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Simply try to insert the favorite
            // If there's a duplicate, it will throw an error that contains "duplicate key"
            try await supabase.from("favorites")
                .insert([
                    "user_id": userId.uuidString,
                    "attraction_id": attractionId.uuidString
                ])
                .execute()
            
            isLoading = false
            return true
        } catch {
            // If the error is about a duplicate key, consider it a success
            // This means the item is already a favorite
            if error.localizedDescription.contains("duplicate key") {
                print("Item is already a favorite - treating as success")
                isLoading = false
                return true
            }
            
            // Otherwise, it's a real error
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
            return true
        } catch {
            isLoading = false
            self.error = "Failed to remove from favorites: \(error.localizedDescription)"
            return false
        }
    }
    
    // In AttractionViewModel.swift, modify the isFavorite function:
    func isFavorite(attractionId: UUID) -> Bool {
        // Add some debug info
        print("Checking if \(attractionId) is a favorite")
        print("Current favorites: \(favoriteAttractions.map { $0.id })")
        
        // Check if the attraction ID is in the user's favorites
        return favoriteAttractions.contains(where: { $0.id == attractionId })
    }

}
