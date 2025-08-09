import SwiftUI
import UIKit

// MARK: - Gradients
struct AppGradients {
    static let primary = LinearGradient(
        colors: [Color.accent, Color.accentLight],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let subtleBackground = LinearGradient(
        colors: [Color.background, Color.cardBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Background
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color.background
            // Soft accents adapt to scheme via dynamic colors above
            Circle()
                .fill(Color.accent.opacity(0.14))
                .frame(width: 420, height: 420)
                .blur(radius: 50)
                .offset(x: -120, y: -280)
            Circle()
                .fill(Color.accentLight.opacity(0.14))
                .frame(width: 520, height: 520)
                .blur(radius: 60)
                .offset(x: 160, y: 280)
            RoundedRectangle(cornerRadius: 600)
                .fill(Color.cardBackground.opacity(0.4))
                .frame(width: 900, height: 900)
                .rotationEffect(.degrees(12))
                .offset(x: 320, y: -420)
                .blur(radius: 70)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppGradients.primary)
            .cornerRadius(25)
            .shadow(color: Color.accent.opacity(0.25), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accent.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Card Styling
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.white.opacity(0.25))
                    )
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
            )
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

// MARK: - Navigation Appearance
enum AppTheme {
    static func setupAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        navAppearance.backgroundColor = UIColor.clear
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.accent)

        // Toolbars
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithTransparentBackground()
        toolbarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        if #available(iOS 15.0, *) {
            UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        }
    }
}


