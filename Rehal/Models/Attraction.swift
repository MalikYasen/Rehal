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
        
        // Handle description which might be missing or null
        if let desc = try? container.decode(String.self, forKey: .description) {
            description = desc
        } else {
            description = "No description available"  // Default value
            print("Missing description for attraction")
        }
        
        category = try container.decode(String.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        priceLevel = try container.decodeIfPresent(Int.self, forKey: .priceLevel)
        
        // Flexible date handling
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try multiple date formats for created_at
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            if let date = dateFormatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                dateFormatter.formatOptions = [.withInternetDateTime]
                if let date = dateFormatter.date(from: dateString) {
                    createdAt = date
                } else {
                    print("Failed to parse date: \(dateString), using current date")
                    createdAt = Date()
                }
            }
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        // Similar approach for updated_at
        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            if let date = dateFormatter.date(from: dateString) {
                updatedAt = date
            } else {
                // Try without fractional seconds
                dateFormatter.formatOptions = [.withInternetDateTime]
                if let date = dateFormatter.date(from: dateString) {
                    updatedAt = date
                } else {
                    print("Failed to parse date: \(dateString), using current date")
                    updatedAt = Date()
                }
            }
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
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
