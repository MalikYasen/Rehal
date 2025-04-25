import Foundation
import Supabase

@MainActor
class AttractionViewModel: ObservableObject {
    @Published var attractions: [Attraction] = []
    @Published var favoriteAttractions: [Attraction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func fetchAttractions(category: String? = nil) async {
        isLoading = true
        error = nil
        
        do {
            var query = supabase.from("attractions").select()
            
            if let category = category {
                query = query.eq("category", value: category)
            }
            
            let response = try await query.execute()
            
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
            self.error = "Failed to fetch attractions: \(error.localizedDescription)"
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
            try await supabase.from("favorites")
                .insert([
                    "user_id": userId.uuidString,
                    "attraction_id": attractionId.uuidString
                ])
                .execute()
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Failed to add to favorites: \(error.localizedDescription)"
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
    
    func isFavorite(attractionId: UUID) -> Bool {
        return favoriteAttractions.contains(where: { $0.id == attractionId })
    }
}
