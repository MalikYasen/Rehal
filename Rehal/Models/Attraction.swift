// AttractionModel.swift
import Foundation
import CoreLocation

struct Attraction: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var category: String
    var subcategory: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var images: [String]?
    var priceLevel: Int?
    var createdAt: Date
    var updatedAt: Date
    
    var location: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, subcategory, address, latitude, longitude, images
        case priceLevel = "price_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

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

// WorkingHoursModel.swift
import Foundation

struct WorkingHours: Identifiable, Codable {
    var id: UUID
    var attractionId: UUID
    var day: String
    var openTime: String?
    var closeTime: String?
    var isOpen: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, day
        case attractionId = "attraction_id"
        case openTime = "open_time"
        case closeTime = "close_time"
        case isOpen = "is_open"
    }
}

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
