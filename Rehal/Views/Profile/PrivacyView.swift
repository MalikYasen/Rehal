import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Define the custom purple color (same as login page)
    let logoPurple = Color(
        red: 121 / 255.0,
        green: 65 / 255.0,
        blue: 234 / 255.0,
        opacity: 1.0
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Introduction
                Text("Last updated: May 1, 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                sectionTitle("Introduction")
                Text("Rehal ('we', 'our', or 'us') respects your privacy and is committed to protecting your personal data. This privacy policy will inform you about how we handle your personal data when you use our app and tell you about your privacy rights.")
                
                sectionTitle("Information We Collect")
                Text("We collect several types of information from and about users of our app, including:")
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Personal information: name, email address, and profile data")
                    bulletPoint("Location data to provide you with accurate local attraction information")
                    bulletPoint("User content such as reviews, ratings, and photos you upload")
                    bulletPoint("Usage data and analytics to improve our services")
                }
                
                sectionTitle("How We Use Your Information")
                Text("We use the information we collect to:")
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Provide and personalize our services")
                    bulletPoint("Process your requests and transactions")
                    bulletPoint("Improve and develop our app")
                    bulletPoint("Communicate with you about updates and promotions")
                    bulletPoint("Protect against fraudulent or illegal activity")
                }
                
                sectionTitle("Data Storage and Security")
                Text("Your data is stored securely using Supabase, a data platform with industry-standard security practices. We implement appropriate technical and organizational measures to protect your personal data against unauthorized or unlawful processing, accidental loss, destruction, or damage.")
                
                sectionTitle("Your Rights")
                Text("Depending on your location, you may have certain rights regarding your personal information, including:")
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Right to access your data")
                    bulletPoint("Right to correct inaccurate data")
                    bulletPoint("Right to delete your data")
                    bulletPoint("Right to restrict processing")
                    bulletPoint("Right to data portability")
                }
                
                sectionTitle("Children's Privacy")
                Text("Our app is not intended for children under 13, and we do not knowingly collect data from children under 13. If we learn we have collected or received personal data from a child under 13, we will delete that information.")
                
                sectionTitle("Changes to Our Privacy Policy")
                Text("We may update our privacy policy from time to time. If we make material changes, we will notify you through the app or by other means.")
                
                sectionTitle("Contact Us")
                Text("If you have any questions about this privacy policy or our data practices, please contact us at:")
                Text("privacy@rehal.app")
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationBarTitle("Privacy", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(logoPurple)
        })
    }
    
    // Helper views for consistent styling
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .padding(.top, 10)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .foregroundColor(logoPurple)
            Text(text)
                .font(.body)
        }
        .padding(.leading, 4)
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyView()
        }
    }
}
