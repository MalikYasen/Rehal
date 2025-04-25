// Add these to your HomeView.swift file or create separate files

import SwiftUICore
import SwiftUI


struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .purple : .primary)
                .cornerRadius(20)
        }
    }
}

struct CategoryButton: View {
    let category: HomeView.Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray6))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .purple : .primary)
                }
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .purple : .primary)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
    }
}
