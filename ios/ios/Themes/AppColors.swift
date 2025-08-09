import SwiftUI
import UIKit

extension Color {
    // Primary palette inspired by icon.png (coral red + warm brown over charcoal)
    static let accent = Color(red: 1.00, green: 0.29, blue: 0.29) // ~#FF4A4A coral
    static let accentLight = Color(red: 1.00, green: 0.43, blue: 0.37) // ~#FF6D5E soft coral

    // Adaptive backgrounds: lighter in light mode, bold in dark mode
    static var background: Color {
        dynamicColor(
            light: UIColor(white: 0.98, alpha: 1.0),              // near-white canvas
            dark: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0) // charcoal
        )
    }

    static var cardBackground: Color {
        dynamicColor(
            light: UIColor(red: 1.0, green: 0.96, blue: 0.94, alpha: 1.0),  // warm off‑white
            dark: UIColor(red: 0.18, green: 0.13, blue: 0.11, alpha: 1.0)   // warm brown
        )
    }
    
    // Highlighted geofence colors
    static let highlightedGeofence = Color(red: 1.00, green: 0.42, blue: 0.34) // vivid coral
    static let highlightedGeofenceLight = Color(red: 1.00, green: 0.54, blue: 0.46)

    // Helper for dynamic colors
    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
} 