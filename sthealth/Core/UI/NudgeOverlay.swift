//
//  NudgeOverlay.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import SwiftUI

struct NudgeOverlay: View {
    let nudge: Nudge
    let onAcknowledge: () -> Void
    
    @State private var breathingScale: CGFloat = 1.0
    @State private var isAppearing = false
    
    private var nudgeColor: Color {
        switch nudge.type {
        case .patternInterruption:
            return .orange.opacity(0.1)
        case .valuesAlignment:
            return .blue.opacity(0.1)
        case .emotionalGranularity:
            return .purple.opacity(0.1)
        case .growthOpportunity:
            return .green.opacity(0.1)
        case .gratitudeStrengths:
            return .yellow.opacity(0.1)
        }
    }
    
    private var accentColor: Color {
        switch nudge.type {
        case .patternInterruption:
            return .orange
        case .valuesAlignment:
            return .blue
        case .emotionalGranularity:
            return .purple
        case .growthOpportunity:
            return .green
        case .gratitudeStrengths:
            return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Leading accent line
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .opacity(isAppearing ? 1.0 : 0.0)
            
            // Main content
            HStack(spacing: 12) {
                // Nudge icon with breathing animation
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: nudgeIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .scaleEffect(breathingScale)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: breathingScale
                )
                
                // Nudge content
                VStack(alignment: .leading, spacing: 4) {
                    Text("💭")
                        .font(.system(size: 12))
                        .opacity(0.7)
                    
                    Text(nudge.content)
                        .font(.appleSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Acknowledge button
                Button(action: onAcknowledge) {
                    Text("✓")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .overlay(
                                    Circle()
                                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(GlassMaterial.primary)
                    
                    // Subtle color tint
                    RoundedRectangle(cornerRadius: 16)
                        .fill(nudgeColor)
                    
                    // Glass highlight
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.glassHighlight, .clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.glassBorder, lineWidth: 0.5)
            )
            .shadow(
                color: .glassShadow.opacity(0.2),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isAppearing ? 1.0 : 0.95)
        .opacity(isAppearing ? 1.0 : 0.0)
        .offset(y: isAppearing ? 0 : -20)
        .onAppear {
            withAnimation(AppAnimation.smooth.delay(0.1)) {
                isAppearing = true
            }
            
            // Start breathing animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                breathingScale = 1.1
            }
        }
        .gesture(
            // Allow swipe up to dismiss
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.height < -30 {
                        onAcknowledge()
                    }
                }
        )
    }
    
    private var nudgeIcon: String {
        switch nudge.type {
        case .patternInterruption:
            return "arrow.triangle.2.circlepath"
        case .valuesAlignment:
            return "heart.circle"
        case .emotionalGranularity:
            return "eye.circle"
        case .growthOpportunity:
            return "arrow.up.circle"
        case .gratitudeStrengths:
            return "star.circle"
        }
    }
}

// MARK: - Nudge Container for HomePage

struct NudgeContainer<Content: View>: View {
    @ObservedObject var nudgeEngine = NudgeEngine.shared
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Nudge overlay (when visible)
            if nudgeEngine.isNudgeVisible, let nudge = nudgeEngine.currentNudge {
                VStack(spacing: 12) {
                    NudgeOverlay(nudge: nudge) {
                        nudgeEngine.acknowledgeNudge()
                    }
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            
            // Main content (shifted down when nudge is visible)
            content
                .animation(AppAnimation.smooth, value: nudgeEngine.isNudgeVisible)
        }
    }
}

#Preview {
    VStack {
        NudgeContainer {
            VStack(spacing: 20) {
                Text("Reflection Box Would Be Here")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                
                Text("Cards Would Be Here")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    .background(Color.primaryBackground)
}