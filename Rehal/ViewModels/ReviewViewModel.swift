import Foundation
import Supabase

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var userReviews: [UUID: Review] = [:] // Map of attraction ID to user's review
    
    private let supabase: SupabaseClient
    private var currentUserId: UUID? = nil
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        // Get the current user ID asynchronously
        Task {
            if let session = try? await supabase.auth.session {
                self.currentUserId = session.user.id
            }
        }
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
            
            // Convert response to reviews using a safer approach
            processReviewsResponse(response, attractionId: attractionId)
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Failed to fetch reviews: \(error.localizedDescription)"
        }
    }
    
    // A more generic approach to process reviews response - now doesn't use async
    private func processReviewsResponse(_ response: Any, attractionId: UUID) {
        guard let responseDict = response as? [String: Any],
              let reviewsData = responseDict["data"] as? [[String: Any]] else {
            reviews = []
            return
        }
        
        var fetchedReviews: [Review] = []
        
        for reviewData in reviewsData {
            do {
                // Extract userName from profiles if available
                var userName: String? = nil
                if let profiles = reviewData["profiles"] as? [String: Any],
                   let fullName = profiles["full_name"] as? String {
                    userName = fullName
                }
                
                // Create a cleaned-up dictionary for the review
                var cleanReview: [String: Any] = [:]
                
                // ID
                if let idString = reviewData["id"] as? String,
                   let id = UUID(uuidString: idString) {
                    cleanReview["id"] = id
                } else {
                    // Skip this review if ID is invalid
                    continue
                }
                
                // Attraction ID
                if let attractionIdStr = reviewData["attraction_id"] as? String,
                   let attrId = UUID(uuidString: attractionIdStr) {
                    cleanReview["attractionId"] = attrId
                } else {
                    cleanReview["attractionId"] = attractionId
                }
                
                // User ID
                if let userIdStr = reviewData["user_id"] as? String,
                   let userId = UUID(uuidString: userIdStr) {
                    cleanReview["userId"] = userId
                } else {
                    // Skip this review if user ID is invalid
                    continue
                }
                
                // Rating (handle different types)
                let rating: Int
                if let ratingInt = reviewData["rating"] as? Int {
                    rating = ratingInt
                } else if let ratingStr = reviewData["rating"] as? String,
                          let ratingInt = Int(ratingStr) {
                    rating = ratingInt
                } else {
                    // Default rating if conversion fails
                    rating = 3
                }
                cleanReview["rating"] = rating
                
                // Comment
                cleanReview["comment"] = reviewData["comment"] as? String
                
                // Images
                if let imagesArray = reviewData["images"] as? [String] {
                    cleanReview["images"] = imagesArray
                } else {
                    cleanReview["images"] = [String]()
                }
                
                // Created At
                if let createdAtStr = reviewData["created_at"] as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = formatter.date(from: createdAtStr) {
                        cleanReview["createdAt"] = date
                    } else {
                        cleanReview["createdAt"] = Date()
                    }
                } else {
                    cleanReview["createdAt"] = Date()
                }
                
                // Manually create a Review object
                let review = Review(
                    id: cleanReview["id"] as! UUID,
                    attractionId: cleanReview["attractionId"] as! UUID,
                    userId: cleanReview["userId"] as! UUID,
                    rating: cleanReview["rating"] as! Int,
                    comment: cleanReview["comment"] as? String,
                    images: cleanReview["images"] as? [String],
                    createdAt: cleanReview["createdAt"] as! Date,
                    userName: userName
                )
                
                fetchedReviews.append(review)
                
                // Store user reviews for quick access - using previously stored user ID
                if let currentUserId = self.currentUserId, review.userId == currentUserId {
                    userReviews[review.attractionId] = review
                }
            } catch {
                print("Error processing review: \(error)")
            }
        }
        
        reviews = fetchedReviews
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
        
        // Check if user already has a review for this attraction
        let existingReview = userReviews[attractionId]
        
        do {
            if let existingReview = existingReview {
                // Update existing review - separate each field to avoid type confusion
                try await supabase.from("reviews")
                    .update(["rating": rating])
                    .eq("id", value: existingReview.id.uuidString)
                    .execute()
                    
                // Only update comment if not empty
                if !comment.isEmpty {
                    try await supabase.from("reviews")
                        .update(["comment": comment])
                        .eq("id", value: existingReview.id.uuidString)
                        .execute()
                } else {
                    try await supabase.from("reviews")
                        .update(["comment": nil as String?])
                        .eq("id", value: existingReview.id.uuidString)
                        .execute()
                }
                
                // Only update images if provided
                if let imageArray = images, !imageArray.isEmpty {
                    try await supabase.from("reviews")
                        .update(["images": imageArray])
                        .eq("id", value: existingReview.id.uuidString)
                        .execute()
                } else {
                    try await supabase.from("reviews")
                        .update(["images": nil as [String]?])
                        .eq("id", value: existingReview.id.uuidString)
                        .execute()
                }
            } else {
                // Create a properly typed input object for new review
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
            }
            
            // Refresh reviews for this attraction
            await fetchReviews(for: attractionId)
            
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
            
            // Update local state
            if let review = reviews.first(where: { $0.id == id }) {
                userReviews.removeValue(forKey: review.attractionId)
            }
            
            reviews.removeAll(where: { $0.id == id })
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Failed to delete review: \(error.localizedDescription)"
            return false
        }
    }
    
    func userHasReviewed(attractionId: UUID) -> Bool {
        return userReviews[attractionId] != nil
    }
    
    func getUserReview(for attractionId: UUID) -> Review? {
        return userReviews[attractionId]
    }
    
    // Get ratings distribution for analytics
    func getRatingsDistribution() -> [Int: Int] {
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for review in reviews {
            distribution[review.rating, default: 0] += 1
        }
        
        return distribution
    }
    
    // Calculate average rating
    func calculateAverageRating() -> Double {
        if reviews.isEmpty {
            return 0.0
        }
        
        let sum = reviews.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(reviews.count)
    }
}
