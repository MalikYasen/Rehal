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
    
    // Add custom initialization to handle potential issues with UUID string parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID which might be a string in the JSON
        if let idString = try? container.decode(String.self, forKey: .id) {
            if let uuid = UUID(uuidString: idString) {
                id = uuid
            } else {
                throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string: \(idString)")
            }
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        // Decode other properties
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .category)
        category = try container.decode(String.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        priceLevel = try container.decodeIfPresent(Int.self, forKey: .priceLevel)
        
        // Handle dates which might need special decoding
        if let dateString = try? container.decode(String.self, forKey: .createdAt),
           let date = ISO8601DateFormatter().date(from: dateString) {
            createdAt = date
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let dateString = try? container.decode(String.self, forKey: .updatedAt),
           let date = ISO8601DateFormatter().date(from: dateString) {
            updatedAt = date
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
    }
    
    init(id: UUID, name: String, description: String, category: String, subcategory: String? = nil,
         address: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
         images: [String]? = nil, priceLevel: Int? = nil,
         createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.subcategory = subcategory
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.images = images
        self.priceLevel = priceLevel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}




