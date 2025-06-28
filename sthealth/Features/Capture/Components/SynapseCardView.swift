import SwiftUI

struct SynapseCardView: View {
    var hypothesis: Hypothesis
    @State private var isShimmering = false
    
    // Mock emotion data - in real app this would come from the hypothesis
    private var primaryEmotion: String {
        // This would be determined by the AI backend
        let emotions = ["joy", "contemplation", "curiosity", "introspection", "awareness"]
        return emotions.randomElement() ?? "neutral"
    }
    
    private var secondaryEmotion: String {
        // This would be determined by the AI backend  
        let emotions = ["calm", "focused", "reflective", "thoughtful", "engaged"]
        return emotions.randomElement() ?? "neutral"
    }
    
    var body: some View {
        ZStack {
            // Apple Glass card background
            ZStack {
                // Primary glass layer
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(
                        EmotionGradients.gradient(primary: primaryEmotion, secondary: secondaryEmotion)
                            .opacity(0.85)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                            .fill(GlassMaterial.primary)
                    )
                
                // Glass overlay with depth
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .glassHighlight,
                                .clear,
                                .clear,
                                .glassSurface
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Shimmer effect layer
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isShimmering ? 0.6 : 0.2)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isShimmering)
            }
            .overlay(
                // Glass border
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: GlassStyle.borderWidth)
            )
            .shadow(
                color: .glassShadow.opacity(0.3),
                radius: GlassStyle.shadowRadius,
                x: GlassStyle.shadowOffset.width,
                y: GlassStyle.shadowOffset.height
            )
            
            // Card content
            VStack(spacing: 0) {
                // Header with icon
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Insight")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
                .padding(.bottom, 12)
                
                // Main question text
                VStack(spacing: 8) {
                    Text(hypothesis.question_text)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .minimumScaleFactor(0.85)
                        .lineSpacing(4)
                        .frame(maxHeight: .infinity)
                    
                    // Emotion tags
                    HStack(spacing: 8) {
                        EmotionTag(emotion: primaryEmotion, isPrimary: true)
                        EmotionTag(emotion: secondaryEmotion, isPrimary: false)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .frame(width: UIScreen.main.bounds.width - 120, height: 300)
        .onAppear {
            isShimmering = true
        }
    }
}

// MARK: - Emotion Tag
struct EmotionTag: View {
    let emotion: String
    let isPrimary: Bool
    
    var body: some View {
        Text(emotion.capitalized)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(isPrimary ? .white : .white.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.white.opacity(isPrimary ? 0.25 : 0.15))
                    .background(
                        Capsule()
                            .fill(GlassMaterial.tertiary)
                            .opacity(0.3)
                    )
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.4), lineWidth: 0.5)
                    )
            )
    }
}


#Preview {
    VStack(spacing: 20) {
        SynapseCardView(hypothesis: Hypothesis(id: 1, question_text: "Do you find that your creativity flows better in the morning or evening? Your recent reflections suggest interesting patterns around your optimal creative hours."))
        
        SynapseCardView(hypothesis: Hypothesis(id: 2, question_text: "Is there a connection between your social interactions and your energy levels?"))
    }
    .padding()
    .background(Color.primaryBackground)
}