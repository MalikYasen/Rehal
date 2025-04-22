//
//  Attraction.swift
//  Rehal
//
//  Created by Malik Yaseen on 19/04/2025.
//

// AttractionModel.swift
import Foundation
import CoreLocation

struct Attraction: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let subcategory: String
    let imageURLs: [URL]
    let rating: Double
    let reviewCount: Int
    let location: CLLocationCoordinate2D
    let address: String
    let workingHours: [WorkingHours]
    let priceLevel: Int // 1-4, representing $ to $$$$
    let contactInfo: ContactInfo
    let reviews: [Review]
    
    struct WorkingHours: Identifiable {
        let id = UUID()
        let day: String
        let open: String
        let close: String
        var isOpen: Bool
        
        // Helper to check if currently open
        var isCurrentlyOpen: Bool {
            // Implementation would check current time against hours
            return isOpen
        }
    }
    
    struct ContactInfo {
        let phone: String?
        let website: URL?
        let email: String?
        let socialMedia: [SocialMedia]?
        
        struct SocialMedia {
            let platform: String
            let url: URL
        }
    }
    
    struct Review: Identifiable {
        let id: String
        let userName: String
        let userImage: URL?
        let rating: Int // 1-5
        let comment: String
        let date: Date
        let images: [URL]?
    }
}

// Sample data for preview
extension Attraction {
    static var sample: Attraction {
        Attraction(
            id: "1",
            name: "Bahrain National Museum",
            description: "The Bahrain National Museum is the largest and one of the oldest public museums in Bahrain. It is constructed near the King Faisal Highway in Manama and opened in December 1988.",
            category: "Historical Sites",
            subcategory: "Museums",
            imageURLs: [
                URL(string: "https://example.com/museum1.jpg")!,
                URL(string: "https://example.com/museum2.jpg")!
            ],
            rating: 4.7,
            reviewCount: 342,
            location: CLLocationCoordinate2D(latitude: 26.2486, longitude: 50.6086),
            address: "Building 273, Road 4204, Manama, Bahrain",
            workingHours: [
                WorkingHours(day: "Monday", open: "8:00 AM", close: "8:00 PM", isOpen: true),
                WorkingHours(day: "Tuesday", open: "8:00 AM", close: "8:00 PM", isOpen: true),
                WorkingHours(day: "Wednesday", open: "8:00 AM", close: "8:00 PM", isOpen: true),
                WorkingHours(day: "Thursday", open: "8:00 AM", close: "8:00 PM", isOpen: true),
                WorkingHours(day: "Friday", open: "8:00 AM", close: "8:00 PM", isOpen: true),
                WorkingHours(day: "Saturday", open: "8:00 AM", close: "8:00 PM", isOpen: true),
                WorkingHours(day: "Sunday", open: "8:00 AM", close: "8:00 PM", isOpen: true)
            ],
            priceLevel: 2,
            contactInfo: ContactInfo(
                phone: "+973 1729 8777",
                website: URL(string: "https://culture.gov.bh/en/authority/cultural_sites/BahrainNationalMuseum/"),
                email: "info@culture.gov.bh",
                socialMedia: [
                    ContactInfo.SocialMedia(platform: "Instagram", url: URL(string: "https://www.instagram.com/bahrainnationalmuseum/")!)
                ]
            ),
            reviews: [
                Review(
                    id: "r1",
                    userName: "Ahmed Ali",
                    userImage: URL(string: "https://example.com/user1.jpg"),
                    rating: 5,
                    comment: "Amazing museum with rich history of Bahrain. The artifacts are well preserved and the information provided is very educational.",
                    date: Date().addingTimeInterval(-7*24*60*60), // 1 week ago
                    images: nil
                ),
                Review(
                    id: "r2",
                    userName: "Sarah Johnson",
                    userImage: URL(string: "https://example.com/user2.jpg"),
                    rating: 4,
                    comment: "Great place to learn about Bahraini culture and history. The building itself is beautiful and the exhibits are interesting.",
                    date: Date().addingTimeInterval(-14*24*60*60), // 2 weeks ago
                    images: [URL(string: "https://example.com/review1.jpg")!]
                )
            ]
        )
    }
}
