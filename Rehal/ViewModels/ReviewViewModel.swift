import Foundation
import Supabase

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func fetchReviews(for attractionId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // Convert UUID to string for the query
            let attractionIdString = attractionId.uuidString
            
            let response = try await supabase.from("reviews")
                .select("*, profiles(full_name)")
                .eq("attraction_id", value: attractionIdString)
                .order("created_at", ascending: false)
                .execute()
            
            // Convert response to reviews
            if let reviewsData = response.data as? [[String: Any]] {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                var fetchedReviews: [Review] = []
                
                for reviewData in reviewsData {
                    // Extract and handle nested profile data
                    var userName: String? = nil
                    if let profiles = reviewData["profiles"] as? [String: Any],
                       let fullName = profiles["full_name"] as? String {
                        userName = fullName
                    }
                    
                    // Make a copy of the review data without the profiles field
                    var reviewCopy = reviewData
                    reviewCopy.removeValue(forKey: "profiles")
                    
                    // Convert String IDs to UUIDs
                    if let idString = reviewCopy["id"] as? String {
                        reviewCopy["id"] = UUID(uuidString: idString)
                    }
                    
                    if let attractionIdStr = reviewCopy["attraction_id"] as? String {
                        reviewCopy["attraction_id"] = UUID(uuidString: attractionIdStr)
                    }
                    
                    if let userIdStr = reviewCopy["user_id"] as? String {
                        reviewCopy["user_id"] = UUID(uuidString: userIdStr)
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: reviewCopy)
                        
                        // Create a decoder with appropriate strategies
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        do {
                            var review = try decoder.decode(Review.self, from: jsonData)
                            review.userName = userName
                            fetchedReviews.append(review)
                        } catch {
                            print("Error decoding review: \(error)")
                        }
                    } catch {
                        print("Error serializing review: \(error)")
                    }
                }
                
                reviews = fetchedReviews
            } else {
                reviews = []
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to fetch reviews: \(error.localizedDescription)"
        }
    }
    
    struct ReviewInput: Encodable {
        let attraction_id: String
        let user_id: String
        let rating: Int
        let comment: String?
        let images: [String]?
        
        init(attractionId: UUID, userId: UUID, rating: Int, comment: String?, images: [String]?) {
            self.attraction_id = attractionId.uuidString
            self.user_id = userId.uuidString
            self.rating = rating
            self.comment = comment
            self.images = images
        }
    }

    func addReview(attractionId: UUID, userId: UUID, rating: Int, comment: String, images: [String]? = nil) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Create a properly typed input object
            let input = ReviewInput(
                attractionId: attractionId,
                userId: userId,
                rating: rating,
                comment: comment.isEmpty ? nil : comment,
                images: images?.isEmpty ?? true ? nil : images
            )
            
            // Insert the review
            try await supabase.from("reviews")
                .insert(input)
                .execute()
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Failed to add review: \(error.localizedDescription)"
            return false
        }
    }
    
    func deleteReview(id: UUID, userId: UUID) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Convert UUIDs to strings
            let idString = id.uuidString
            let userIdString = userId.uuidString
            
            // Delete the review
            try await supabase.from("reviews")
                .delete()
                .eq("id", value: idString)
                .eq("user_id", value: userIdString)
                .execute()
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Failed to delete review: \(error.localizedDescription)"
            return false
        }
    }
}
