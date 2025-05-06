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
