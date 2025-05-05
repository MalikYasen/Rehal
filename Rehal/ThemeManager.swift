// ThemeManager.swift
import SwiftUI

enum ColorSchemePreference: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var colorSchemePreference: ColorSchemePreference = .system {
        didSet {
            UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: "colorSchemePreference")
        }
    }
    
    init() {
        if let savedPreference = UserDefaults.standard.string(forKey: "colorSchemePreference"),
           let preference = ColorSchemePreference(rawValue: savedPreference) {
            colorSchemePreference = preference
        }
    }
    
    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
