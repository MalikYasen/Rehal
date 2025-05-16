import Foundation

struct Review: Identifiable, Codable, Equatable {
    var id: UUID
    var attractionId: UUID
    var userId: UUID
    var rating: Int
    var comment: String?
    var images: [String]?
    var createdAt: Date
    var userName: String?  // This is not in the DB, we'll populate it separately
    
    enum CodingKeys: String, CodingKey {
        case id, comment, rating, images
        case attractionId = "attraction_id"
        case userId = "user_id"
        case createdAt = "created_at"
        // userName is not in the database schema
    }
    
    // Add a custom initializer for our manual creation
    init(id: UUID, attractionId: UUID, userId: UUID, rating: Int, comment: String?, images: [String]?, createdAt: Date, userName: String?) {
        self.id = id
        self.attractionId = attractionId
        self.userId = userId
        self.rating = rating
        self.comment = comment
        self.images = images
        self.createdAt = createdAt
        self.userName = userName
    }
    
    // Static method to create a placeholder review
    static func placeholder(id: UUID = UUID(), attractionId: UUID) -> Review {
        Review(
            id: id,
            attractionId: attractionId,
            userId: UUID(),
            rating: 5,
            comment: "Great place!",
            images: nil,
            createdAt: Date(),
            userName: "Test User"
        )
    }
    
    // Implement Equatable to check for equality
    static func == (lhs: Review, rhs: Review) -> Bool {
        return lhs.id == rhs.id
    }
}
