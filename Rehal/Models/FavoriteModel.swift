// FavoriteModel.swift
import Foundation

struct Favorite: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var attractionId: UUID
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case attractionId = "attraction_id"
        case createdAt = "created_at"
    }
}
