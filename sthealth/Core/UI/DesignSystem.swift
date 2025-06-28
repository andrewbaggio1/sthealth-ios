//
//  DesignSystem.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/01/25.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    // iOS 26 Apple Glass Color Palette
    static let primaryBackground = Color(hex: "#F8F9FA")
    static let secondaryBackground = Color(hex: "#FAFBFC")
    static let glassBackground = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Apple Glass Text Colors
    static let primaryText = Color(hex: "#1C1C1E")
    static let secondaryText = Color(hex: "#3C3C43").opacity(0.75)
    static let tertiaryText = Color(hex: "#3C3C43").opacity(0.45)
    static let quaternaryText = Color(hex: "#3C3C43").opacity(0.25)
    
    // Apple Glass Accent Colors
    static let primaryAccent = Color(hex: "#007AFF")
    static let secondaryAccent = Color(hex: "#5856D6")
    static let successAccent = Color(hex: "#30D158")
    static let warningAccent = Color(hex: "#FF9F0A")
    static let errorAccent = Color(hex: "#FF453A")
    
    // Glass Material Effects
    static let glassSurface = Color.white.opacity(0.1)
    static let glassHighlight = Color.white.opacity(0.3)
    static let glassShadow = Color.black.opacity(0.05)
    
    // Swipe Colors (updated for glass theme)
    static let swipeGreen = Color(hex: "#30D158")
    static let swipeRed = Color(hex: "#FF453A")
    static let swipePurple = Color(hex: "#5856D6")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct EmotionGradients {
    static func gradient(primary: String?, secondary: String?) -> LinearGradient {
        let primaryColor = enhancedColor(for: primary)
        let secondaryColor = enhancedColor(for: secondary)
        
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: primaryColor, location: 0.0),
                .init(color: primaryColor.opacity(0.8), location: 0.3),
                .init(color: secondaryColor.opacity(0.7), location: 0.7),
                .init(color: secondaryColor, location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private static func enhancedColor(for emotion: String?) -> Color {
        switch emotion?.lowercased() {
        // Primary emotions
        case "joy", "happiness": return Color(hex: "#FFD60A")
        case "sadness", "melancholy": return Color(hex: "#007AFF")
        case "anger", "frustration": return Color(hex: "#FF453A")
        case "fear", "anxiety": return Color(hex: "#5E5CE6")
        case "surprise", "wonder": return Color(hex: "#FF9F0A")
        case "disgust": return Color(hex: "#32AE85")
        
        // Cognitive states
        case "contemplation", "thoughtful": return Color(hex: "#5856D6")
        case "curiosity", "interested": return Color(hex: "#007AFF")
        case "introspection", "reflective": return Color(hex: "#8E4EC6")
        case "awareness", "mindful": return Color(hex: "#32AE85")
        case "calm", "peaceful": return Color(hex: "#30B0C7")
        case "focused", "concentrated": return Color(hex: "#007AFF")
        case "engaged", "active": return Color(hex: "#FF9F0A")
        
        // Default
        default: return Color(hex: "#8E8E93")
        }
    }
}

// MARK: - Glass Material System
struct GlassMaterial {
    static let primary = Material.ultraThinMaterial
    static let secondary = Material.thinMaterial
    static let tertiary = Material.regularMaterial
    static let thick = Material.thickMaterial
}

// MARK: - Glass Styling
struct GlassStyle {
    static let cornerRadius: CGFloat = 20
    static let borderWidth: CGFloat = 0.5
    static let shadowRadius: CGFloat = 20
    static let shadowOffset = CGSize(width: 0, height: 8)
    
    static func glassCard(cornerRadius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(GlassMaterial.primary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.2), lineWidth: borderWidth)
            )
            .shadow(color: .glassShadow, radius: shadowRadius, x: shadowOffset.width, y: shadowOffset.height)
    }
    
    static func glassButton(cornerRadius: CGFloat = 16) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(GlassMaterial.secondary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .glassShadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Typography System
extension Font {
    static let appleTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let appleLargeTitle = Font.system(size: 40, weight: .bold, design: .rounded)
    static let appleHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let appleBody = Font.system(size: 17, weight: .regular, design: .default)
    static let appleCallout = Font.system(size: 16, weight: .regular, design: .default)
    static let appleSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let appleFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let appleCaption = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - Animation System
struct AppAnimation {
    static let standard = Animation.interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 0)
    static let fluid = Animation.interpolatingSpring(stiffness: 300, damping: 25, initialVelocity: 0)
    static let gentle = Animation.interpolatingSpring(stiffness: 200, damping: 20, initialVelocity: 0)
    static let quick = Animation.easeInOut(duration: 0.2)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let glass = Animation.interpolatingSpring(stiffness: 400, damping: 30, initialVelocity: 0)
}
