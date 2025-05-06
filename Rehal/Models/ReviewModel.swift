// ReviewModel.swift
import Foundation

struct Review: Identifiable, Codable {
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
        case userName // This won't be in the JSON
    }
}
