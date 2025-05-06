import Foundation
import SwiftUI
import Supabase

@MainActor
class StorageService: ObservableObject {
    private let supabase: SupabaseClient
    @Published var isUploading = false
    @Published var error: String?
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func uploadImage(_ image: UIImage, path: String, bucketId: String = "attractions") async -> String? {
        isUploading = true
        error = nil
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            error = "Failed to convert image to data"
            isUploading = false
            return nil
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let fullPath = "\(path)/\(fileName)"
        
        do {
            // Creating FileOptions with required parameters
            let fileOptions = FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg"
            )
            
            // Use the updated API signature
            try await supabase.storage
                .from(bucketId)
                .upload(
                    fullPath,
                    data: imageData,
                    options: fileOptions
                )
            
            // Add 'try' to getPublicURL since it can throw
            let publicURL = try supabase.storage
                .from(bucketId)
                .getPublicURL(path: fullPath)
            
            isUploading = false
            return publicURL.absoluteString
        } catch {
            self.error = "Upload failed: \(error.localizedDescription)"
            isUploading = false
            return nil
        }
    }
    
    func deleteImage(path: String, bucketId: String = "attractions") async -> Bool {
        do {
            try await supabase.storage
                .from(bucketId)
                .remove(paths: [path])
            
            return true
        } catch {
            self.error = "Delete failed: \(error.localizedDescription)"
            return false
        }
    }
}
