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
            VStack(spacing: 20) {
                // Header with icon
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                    
                    Text("Insight")
                        .font(.appleCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                
                Spacer()
                
                // Main question text
                VStack(spacing: 16) {
                    Text(hypothesis.question_text)
                        .font(.appleHeadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .lineSpacing(2)
                    
                    // Emotion tags
                    HStack(spacing: 10) {
                        EmotionTag(emotion: primaryEmotion, isPrimary: true)
                        EmotionTag(emotion: secondaryEmotion, isPrimary: false)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
        .frame(width: 320, height: 420)
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
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(isPrimary ? .white : .white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
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