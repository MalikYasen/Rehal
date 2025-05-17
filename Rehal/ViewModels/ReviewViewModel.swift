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
    
    // Reference to attraction view model for updating ratings
    private var attractionViewModel: AttractionViewModel?
    
    // Set the attraction view model reference
    func setAttractionViewModel(_ viewModel: AttractionViewModel) {
        attractionViewModel = viewModel
    }
    
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
        reviews = [] // Start with empty array
        
        do {
            print("Fetching reviews for attraction: \(attractionId.uuidString)")
            
            // Get raw reviews data - no join since relationship doesn't exist
            let response = try await supabase.from("reviews")
                .select("*")
                .eq("attraction_id", value: attractionId.uuidString)
                .execute()
            
            print("Reviews fetch response received: \(response)")
            
            // Extract data from response
            let responseData = response.data
            
            // Debug the data
            if let dataSize = (responseData as? Data)?.count {
                print("Response data is Data type with size: \(dataSize) bytes")
            } else {
                print("Response data is not Data type: \(type(of: responseData))")
            }
            
            // Convert Data to JSON
            if let data = responseData as? Data {
                do {
                    let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                    print("Successfully decoded JSON data. Found \(jsonArray?.count ?? 0) reviews")
                    
                    guard let jsonArray = jsonArray else {
                        print("Failed to decode JSON array from data")
                        isLoading = false
                        return
                    }
                    
                    // Process manually for more reliable parsing
                    var fetchedReviews: [Review] = []
                    
                    for reviewData in jsonArray {
                        do {
                            print("Processing review: \(reviewData["id"] ?? "unknown id")")
                            
                            // ID
                            guard let idString = reviewData["id"] as? String,
                                  let id = UUID(uuidString: idString) else {
                                print("Invalid review ID format")
                                continue
                            }
                            
                            // Attraction ID
                            guard let attractionIdStr = reviewData["attraction_id"] as? String,
                                  let attrId = UUID(uuidString: attractionIdStr) else {
                                print("Invalid attraction ID format")
                                continue
                            }
                            
                            // User ID
                            guard let userIdStr = reviewData["user_id"] as? String,
                                  let userId = UUID(uuidString: userIdStr) else {
                                print("Invalid user ID format")
                                continue
                            }
                            
                            // Rating
                            let rating: Int
                            if let ratingInt = reviewData["rating"] as? Int {
                                rating = ratingInt
                            } else if let ratingDouble = reviewData["rating"] as? Double {
                                rating = Int(ratingDouble)
                            } else if let ratingStr = reviewData["rating"] as? String,
                                      let ratingInt = Int(ratingStr) {
                                rating = ratingInt
                            } else {
                                print("Invalid rating format")
                                rating = 3 // Default
                            }
                            
                            // Comment
                            let comment = reviewData["comment"] as? String
                            
                            // Images
                            let images: [String]?
                            if let imagesArray = reviewData["images"] as? [String] {
                                images = imagesArray
                            } else {
                                images = nil
                            }
                            
                            // Created At
                            var createdAt = Date()
                            if let createdAtStr = reviewData["created_at"] as? String {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                if let date = formatter.date(from: createdAtStr) {
                                    createdAt = date
                                } else {
                                    // Try alternative format without fractional seconds
                                    formatter.formatOptions = [.withInternetDateTime]
                                    if let date = formatter.date(from: createdAtStr) {
                                        createdAt = date
                                    } else {
                                        print("Failed to parse date: \(createdAtStr)")
                                    }
                                }
                            }
                            
                            // Create review object
                            let review = Review(
                                id: id,
                                attractionId: attrId,
                                userId: userId,
                                rating: rating,
                                comment: comment,
                                images: images,
                                createdAt: createdAt,
                                userName: nil // We'll fetch user names separately
                            )
                            
                            fetchedReviews.append(review)
                            
                            // Store user reviews for quick access
                            if let currentUserId = self.currentUserId, review.userId == currentUserId {
                                userReviews[review.attractionId] = review
                            }
                        } catch {
                            print("Error processing individual review: \(error)")
                        }
                    }
                    
                    // Update reviews array
                    await MainActor.run {
                        self.reviews = fetchedReviews
                        print("Successfully loaded \(fetchedReviews.count) reviews")
                        
                        // Update attraction rating
                        self.attractionViewModel?.updateRating(for: attractionId, with: fetchedReviews)
                        
                        // Fetch user names for the reviews
                        Task {
                            await self.fetchUserNames()
                        }
                    }
                } catch {
                    print("JSON decoding failed: \(error)")
                    self.error = "Failed to decode reviews data: \(error.localizedDescription)"
                }
            } else {
                // If it's not Data, try to cast as JSON array directly
                if let jsonArray = responseData as? [[String: Any]] {
                    print("Response was already in JSON format. Found \(jsonArray.count) reviews")
                    
                    // Process manually for more reliable parsing
                    var fetchedReviews: [Review] = []
                    
                    for reviewData in jsonArray {
                        do {
                            print("Processing review: \(reviewData["id"] ?? "unknown id")")
                            
                            // ID
                            guard let idString = reviewData["id"] as? String,
                                  let id = UUID(uuidString: idString) else {
                                print("Invalid review ID format")
                                continue
                            }
                            
                            // Attraction ID
                            guard let attractionIdStr = reviewData["attraction_id"] as? String,
                                  let attrId = UUID(uuidString: attractionIdStr) else {
                                print("Invalid attraction ID format")
                                continue
                            }
                            
                            // User ID
                            guard let userIdStr = reviewData["user_id"] as? String,
                                  let userId = UUID(uuidString: userIdStr) else {
                                print("Invalid user ID format")
                                continue
                            }
                            
                            // Rating
                            let rating: Int
                            if let ratingInt = reviewData["rating"] as? Int {
                                rating = ratingInt
                            } else if let ratingDouble = reviewData["rating"] as? Double {
                                rating = Int(ratingDouble)
                            } else if let ratingStr = reviewData["rating"] as? String,
                                      let ratingInt = Int(ratingStr) {
                                rating = ratingInt
                            } else {
                                print("Invalid rating format")
                                rating = 3 // Default
                            }
                            
                            // Comment
                            let comment = reviewData["comment"] as? String
                            
                            // Images
                            let images: [String]?
                            if let imagesArray = reviewData["images"] as? [String] {
                                images = imagesArray
                            } else {
                                images = nil
                            }
                            
                            // Created At
                            var createdAt = Date()
                            if let createdAtStr = reviewData["created_at"] as? String {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                if let date = formatter.date(from: createdAtStr) {
                                    createdAt = date
                                } else {
                                    // Try alternative format without fractional seconds
                                    formatter.formatOptions = [.withInternetDateTime]
                                    if let date = formatter.date(from: createdAtStr) {
                                        createdAt = date
                                    } else {
                                        print("Failed to parse date: \(createdAtStr)")
                                    }
                                }
                            }
                            
                            // Create review object
                            let review = Review(
                                id: id,
                                attractionId: attrId,
                                userId: userId,
                                rating: rating,
                                comment: comment,
                                images: images,
                                createdAt: createdAt,
                                userName: nil // We'll fetch user names separately
                            )
                            
                            fetchedReviews.append(review)
                            
                            // Store user reviews for quick access
                            if let currentUserId = self.currentUserId, review.userId == currentUserId {
                                userReviews[review.attractionId] = review
                            }
                        } catch {
                            print("Error processing individual review: \(error)")
                        }
                    }
                    
                    // Update reviews array
                    await MainActor.run {
                        self.reviews = fetchedReviews
                        print("Successfully loaded \(fetchedReviews.count) reviews")
                        
                        // Update attraction rating
                        self.attractionViewModel?.updateRating(for: attractionId, with: fetchedReviews)
                        
                        // Fetch user names for the reviews
                        Task {
                            await self.fetchUserNames()
                        }
                    }
                } else {
                    print("Unexpected response format: \(String(describing: responseData))")
                    
                    // Debug output to understand what we're getting
                    print("Response type: \(type(of: responseData))")
                    if let dataStr = String(data: responseData as? Data ?? Data(), encoding: .utf8) {
                        print("Response as string (first 200 chars): \(String(dataStr.prefix(200)))")
                    }
                    
                    self.error = "Unexpected response format from server"
                }
            }
        } catch {
            self.error = "Failed to fetch reviews: \(error.localizedDescription)"
            print("Reviews fetch error details: \(error)")
        }
        
        isLoading = false
    }
    
    // Update a single review with user info
    func updateReview(with userId: UUID, userName: String) {
        // Update on the main thread since we're modifying published properties
        Task { @MainActor in
            // Find and update all reviews by this user
            self.reviews = self.reviews.map { review in
                if review.userId == userId {
                    var updatedReview = review
                    updatedReview.userName = userName
                    return updatedReview
                }
                return review
            }
            
            // Also update user reviews map
            for (attractionId, review) in userReviews {
                if review.userId == userId {
                    var updatedReview = review
                    updatedReview.userName = userName
                    userReviews[attractionId] = updatedReview
                }
            }
        }
    }
    
    // Fetch user names for reviews
    func fetchUserNames() async {
        guard !reviews.isEmpty else { return }
        
        // Create a unique set of user IDs
        let userIds = Set(reviews.map { $0.userId.uuidString })
        print("Fetching user names for \(userIds.count) users: \(userIds)")

        for userId in userIds {
            do {
                print("Fetching profile for user: \(userId)")
                let response = try await supabase.from("profiles")
                    .select("id, full_name")
                    .eq("id", value: userId)
                    .execute()
                
                if let data = response.data as? Data {
                    do {
                        if let profiles = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                           let profile = profiles.first,
                           let idString = profile["id"] as? String,
                           let profileId = UUID(uuidString: idString),
                           let fullName = profile["full_name"] as? String {
                            
                            print("Got profile name for \(profileId): \(fullName)")
                            
                            // Update reviews with this user's name immediately
                            updateReview(with: profileId, userName: fullName)
                        }
                    } catch {
                        print("Error parsing profile: \(error)")
                    }
                }
            } catch {
                print("Error fetching profile for \(userId): \(error)")
            }
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
        let id: String
        let attraction_id: String
        let user_id: String
        let rating: Int
        let comment: String?
        let images: [String]?
        
        init(attractionId: UUID, userId: UUID, rating: Int, comment: String?, images: [String]?) {
            self.id = UUID().uuidString
            self.attraction_id = attractionId.uuidString
            self.user_id = userId.uuidString
            self.rating = rating
            self.comment = comment
            self.images = images ?? []
        }
    }
    
    // Fix for adding reviews
    func addReview(attractionId: UUID, userId: UUID, rating: Int, comment: String, images: [String]? = nil) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Create an object using the ReviewInput struct with proper field names for Supabase
            let reviewInput = ReviewInput(
                attractionId: attractionId,
                userId: userId,
                rating: rating,
                comment: comment,
                images: images
            )
            
            // Direct insert with the properly structured object
            try await supabase.from("reviews")
                .insert(reviewInput)
                .execute()
            
            // Create a local Review object to add it to our list immediately
            let newReview = Review(
                id: UUID(uuidString: reviewInput.id)!,
                attractionId: attractionId,
                userId: userId,
                rating: rating,
                comment: comment,
                images: images,
                createdAt: Date(),
                userName: nil
            )
            
            // Add to local cache
            await MainActor.run {
                reviews.append(newReview)
                userReviews[attractionId] = newReview
            }
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = "Failed to add review: \(error.localizedDescription)"
            print("Add review error details: \(error)")
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
