//
//  NudgeOverlay.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import SwiftUI

// MARK: - Weekly Summary Nudge View

struct WeeklySummaryNudgeView: View {
    @ObservedObject var summaryEngine = WeeklySummaryEngine.shared
    @State private var isAppearing = false
    @State private var showingWeeklySummary = false
    @State private var star1Opacity: Double = 0.3
    @State private var star2Opacity: Double = 0.5
    @State private var star3Opacity: Double = 0.7
    @State private var star4Opacity: Double = 0.4
    @State private var star5Opacity: Double = 0.6
    @State private var star6Opacity: Double = 0.5
    @State private var star7Opacity: Double = 0.45
    @State private var star8Opacity: Double = 0.65
    @State private var star9Opacity: Double = 0.55
    @State private var star10Opacity: Double = 0.7
    @State private var star11Opacity: Double = 0.4
    @State private var star12Opacity: Double = 0.6
    @State private var starOffset: CGFloat = -50
    
    var body: some View {
        VStack(spacing: 4) {
            // Golden weekly summary card matching nudge style
            HStack(spacing: 12) {
                // Icon matching nudge style
                ZStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.9, green: 0.75, blue: 0.1),
                                    Color(red: 0.85, green: 0.65, blue: 0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Content matching nudge style
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Summary:")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.05))
                    
                    Text("Your growth journey this week is ready to explore")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(Color(UIColor.label))
                        .lineSpacing(2)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Arrow button
                Button(action: { showingWeeklySummary = true }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.05))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // White base like nudge cards
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                    
                    // Golden gradient overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.08),
                                    Color(red: 0.85, green: 0.65, blue: 0.05).opacity(0.05),
                                    Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.03),
                                    Color.white
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            // Moving and twinkling stars in the background
                            ZStack {
                                // Many golden stars across the card
                                Image(systemName: "sparkle")
                                    .font(.system(size: 6))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 20, y: -15)
                                    .opacity(star1Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 5))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 50, y: 10)
                                    .opacity(star2Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 6))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 80, y: -10)
                                    .opacity(star3Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 4))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 110, y: 15)
                                    .opacity(star4Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 5))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 140, y: -5)
                                    .opacity(star5Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 7))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 170, y: 8)
                                    .opacity(star6Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 4))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 200, y: -12)
                                    .opacity(star7Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 6))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 230, y: 12)
                                    .opacity(star8Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 5))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 260, y: -8)
                                    .opacity(star9Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 7))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 290, y: 5)
                                    .opacity(star10Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 4))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 320, y: -10)
                                    .opacity(star11Opacity)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 6))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.6))
                                    .offset(x: starOffset + 350, y: 10)
                                    .opacity(star12Opacity)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 0.5)
            )
            
            // Badge below the card like nudge timer
            Text("NEW THIS WEEK")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.05))
        }
        .padding(.horizontal, 20) // Match reflection box width
        .scaleEffect(isAppearing ? 1.0 : 0.95)
        .opacity(isAppearing ? 1.0 : 0.0)
        .offset(y: isAppearing ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                isAppearing = true
            }
            
            // Stars moving across the card
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                starOffset = 400
            }
            
            // Twinkling stars with different timing
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                star1Opacity = 0.9
            }
            
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
                .delay(0.3)
            ) {
                star2Opacity = 1.0
            }
            
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
                .delay(0.6)
            ) {
                star3Opacity = 0.95
            }
            
            withAnimation(
                .easeInOut(duration: 2.2)
                .repeatForever(autoreverses: true)
                .delay(0.9)
            ) {
                star4Opacity = 0.85
            }
            
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(1.2)
            ) {
                star5Opacity = 1.0
            }
            
            withAnimation(
                .easeInOut(duration: 2.3)
                .repeatForever(autoreverses: true)
                .delay(0.4)
            ) {
                star6Opacity = 0.95
            }
            
            withAnimation(
                .easeInOut(duration: 1.7)
                .repeatForever(autoreverses: true)
                .delay(0.8)
            ) {
                star7Opacity = 0.9
            }
            
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(1.5)
            ) {
                star8Opacity = 1.0
            }
            
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
                .delay(0.2)
            ) {
                star9Opacity = 0.95
            }
            
            withAnimation(
                .easeInOut(duration: 2.1)
                .repeatForever(autoreverses: true)
                .delay(1.0)
            ) {
                star10Opacity = 1.0
            }
            
            withAnimation(
                .easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
                .delay(0.7)
            ) {
                star11Opacity = 0.85
            }
            
            withAnimation(
                .easeInOut(duration: 2.4)
                .repeatForever(autoreverses: true)
                .delay(1.3)
            ) {
                star12Opacity = 1.0
            }
        }
        .sheet(isPresented: $showingWeeklySummary) {
            if let summary = summaryEngine.currentWeeklySummary {
                WeeklySummaryView(summary: summary)
                    .onDisappear {
                        summaryEngine.markSummaryAsViewed(summary)
                    }
            }
        }
    }
}

struct NudgeOverlay: View {
    let nudge: Nudge
    let onAcknowledge: () -> Void
    
    @State private var breathingScale: CGFloat = 1.0
    @State private var isAppearing = false
    @State private var isHearted = false
    @State private var timeRemaining: TimeInterval = 120 // 2 minutes
    @State private var animationOffset: CGFloat = 0
    @State private var gradientRotation: Double = 0
    @State private var timer: Timer?
    
    private var primaryColor: Color {
        // Primary emotion color
        switch nudge.type {
        case .patternInterruption:
            return Color(UIColor.systemOrange)
        case .valuesAlignment:
            return Color(UIColor.systemBlue)
        case .emotionalGranularity:
            return Color(UIColor.systemPurple)
        case .growthOpportunity:
            return Color(UIColor.systemGreen)
        case .gratitudeStrengths:
            return Color(UIColor.systemYellow)
        }
    }
    
    private var secondaryColor: Color {
        // Secondary emotion color - complementary
        switch nudge.type {
        case .patternInterruption:
            return Color(UIColor.systemPink) // Change + Energy
        case .valuesAlignment:
            return Color(UIColor.systemIndigo) // Purpose + Depth
        case .emotionalGranularity:
            return Color(UIColor.systemTeal) // Awareness + Clarity
        case .growthOpportunity:
            return Color(UIColor.systemMint) // Growth + Freshness
        case .gratitudeStrengths:
            return Color(UIColor.systemOrange) // Joy + Warmth
        }
    }
    
    
    var body: some View {
        VStack(spacing: 4) {
            // Nudge card
            HStack(spacing: 12) {
                // Icon matching primary color
                ZStack {
                    Image(systemName: nudgeIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor,
                                    primaryColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                    .onAppear {
                        print("🔍 Nudge type: \(nudge.type), Icon: \(nudgeIcon)")
                    }
                    .scaleEffect(breathingScale)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: breathingScale
                    )
                
                // Nudge content - matching card font weight
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nudge:")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(primaryColor)
                    
                    Text(nudge.content)
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(Color(UIColor.label))
                        .lineSpacing(2)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Heart button with proper hit target
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isHearted = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onAcknowledge()
                    }
                }) {
                    Image(systemName: isHearted ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(isHearted ? Color(UIColor.systemRed) : Color(UIColor.tertiaryLabel))
                        .frame(width: 44, height: 44) // Apple's minimum hit target
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isHearted ? 1.1 : 1.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // White base
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                    
                    // Much more subtle gradient from edges
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor.opacity(0.03),
                                    primaryColor.opacity(0.02),
                                    primaryColor.opacity(0.01),
                                    Color.white
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            primaryColor.opacity(0.025),
                                            primaryColor.opacity(0.015),
                                            primaryColor.opacity(0.008),
                                            Color.white.opacity(0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            primaryColor.opacity(0.025),
                                            primaryColor.opacity(0.015),
                                            primaryColor.opacity(0.008),
                                            Color.white.opacity(0)
                                        ]),
                                        startPoint: .trailing,
                                        endPoint: .leading
                                    )
                                )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 0.5)
            )
            
            // Timer below the card
            Text(formatTimeRemaining())
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .scaleEffect(isAppearing ? 1.0 : 0.95)
        .opacity(isAppearing ? 1.0 : 0.0)
        .offset(y: isAppearing ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                isAppearing = true
            }
            
            // Start breathing animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                breathingScale = 1.05
            }
            
            // Start countdown timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    onAcknowledge()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
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
    
    private func formatTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var nudgeIcon: String {
        let icon: String
        switch nudge.type {
        case .patternInterruption:
            icon = "shuffle"  // Breaking patterns
        case .valuesAlignment:
            icon = "compass.fill"  // Core values & direction
        case .emotionalGranularity:
            icon = "brain.head.profile"  // Emotional awareness (valid SF Symbol)
        case .growthOpportunity:
            icon = "leaf.fill"  // Growth and development
        case .gratitudeStrengths:
            icon = "sparkles"  // Gratitude and positivity
        }
        
        // Verify icon exists, fallback to lightbulb if not
        if UIImage(systemName: icon) != nil {
            return icon
        } else {
            print("⚠️ Icon '\(icon)' not found for nudge type \(nudge.type), using fallback")
            return "lightbulb.fill"
        }
    }
}

// MARK: - Nudge Container for HomePage

struct NudgeContainer<Content: View>: View {
    @ObservedObject var nudgeEngine = NudgeEngine.shared
    @ObservedObject var summaryEngine = WeeklySummaryEngine.shared
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekly summary takes precedence over regular nudges
            if summaryEngine.hasNewWeeklySummary {
                WeeklySummaryNudgeView()
                    .padding(.top, 2)
                    .padding(.bottom, 4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else if nudgeEngine.isNudgeVisible, let nudge = nudgeEngine.currentNudge {
                // Only show regular nudge if no weekly summary
                NudgeOverlay(nudge: nudge) {
                    nudgeEngine.acknowledgeNudge()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Main content (shifted down when nudge/summary is visible)
            content
                .animation(AppAnimation.smooth, value: nudgeEngine.isNudgeVisible || summaryEngine.hasNewWeeklySummary)
        }
    }
}

#Preview("NudgeOverlay") {
    VStack {
        // Test nudge
        NudgeOverlay(
            nudge: Nudge(
                content: "When you feel overwhelmed, what would it look like to pause and observe the feeling without judgment?",
                type: .emotionalGranularity,
                framework: .mindfulness
            ),
            onAcknowledge: {}
        )
        .padding()
        
        Spacer()
        
        // Test with container
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
    .onAppear {
        // Force show a nudge for preview
        NudgeEngine.shared.forceShowNudge()
    }
}