import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
class CaptureViewModel: ObservableObject {
    @Published var hypotheses: [Hypothesis] = []
    @Published var isLoading = false
    @Published var error: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let cognitiveEngine = CognitiveEngine.shared
    private let intelligentMinter = IntelligentCardMinter.shared
    private let engagementTracker = EngagementTracker.shared
    private let analyticsTracker = AnalyticsTracker.shared
    
    // Track if user has seen initial calibration cards
    private var hasSeenInitialCards: Bool {
        get { UserDefaults.standard.bool(forKey: "hasSeenInitialCards") }
        set { UserDefaults.standard.set(newValue, forKey: "hasSeenInitialCards") }
    }
    
    func fetchHypotheses() {
        Task {
            await loadHypotheses()
        }
    }
    
    private func loadHypotheses() async {
        isLoading = true
        error = nil
        
        do {
            if !hasSeenInitialCards {
                // Show the initial 8 calibration cards (only once)
                hypotheses = intelligentMinter.getInitialEightCards()
                hasSeenInitialCards = true
            } else {
                // Try to fetch from backend first
                let backendHypotheses = try? await BackendClient.shared.fetchPendingHypotheses()
                
                if let backendCards = backendHypotheses, !backendCards.isEmpty {
                    hypotheses = backendCards
                } else {
                    // Generate intelligent assumptions based on user behavior
                    let intelligentCards = await intelligentMinter.mintAssumptionCards(limit: 8)
                    
                    if !intelligentCards.isEmpty {
                        hypotheses = intelligentCards
                    } else {
                        // Fallback to default if no patterns detected yet
                        hypotheses = createFallbackHypotheses()
                    }
                }
            }
            
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
            
            // Fallback on error
            hypotheses = hasSeenInitialCards ? createFallbackHypotheses() : intelligentMinter.getInitialEightCards()
        }
    }
    
    // MARK: - Mock Data Generation
    private func createMockMoments() -> [Moment] {
        // This simulates user's previous reflections
        // In a real app, this would query the actual SwiftData/Core Data store
        let mockTexts = [
            "Feeling really creative this morning. Had some great ideas for the project while having coffee.",
            "Social media scroll made me feel anxious again. Why do I keep comparing myself to others?",
            "Evening walk was so peaceful. I should do this more often instead of staying inside.",
            "Work meeting was stressful but I handled it better than usual. Growth!",
            "Noticed I'm more focused when I work in the library vs at home. Interesting pattern.",
            "Feeling grateful for my friends today. Sarah's text really brightened my mood.",
            "Struggled to concentrate after lunch. Maybe I need to eat lighter during the day.",
            "Morning meditation helped center me before the busy day. 10 minutes made a difference."
        ]
        
        var moments: [Moment] = []
        
        for (index, text) in mockTexts.enumerated() {
            let timestamp = Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            
            // Create mock moment (simplified - in real app would use proper SwiftData model)
            let moment = Moment(
                text: text,
                timestamp: timestamp,
                modality: .text
            )
            
            // Add some resonated text for variety
            if index % 2 == 0 {
                moment.resonatedText = text + " This reflection shows a pattern of mindful awareness and self-observation."
            }
            
            moments.append(moment)
        }
        
        return moments
    }
    
    private func createFallbackHypotheses() -> [Hypothesis] {
        // These are gentle assumptions for when we don't have enough data yet
        return [
            Hypothesis(
                id: 9001,
                question_text: "You reflect more when you're processing something important, but you might not realize how much insight you already have."
            ),
            Hypothesis(
                id: 9002, 
                question_text: "Your emotional awareness is developing, but you're still learning to trust your own observations."
            ),
            Hypothesis(
                id: 9003,
                question_text: "You're more self-aware than you give yourself credit for, but you second-guess your instincts."
            )
        ]
    }
    
    // MARK: - User Interactions
    func swipeLeft(hypothesis: Hypothesis) {
        // Track engagement before processing
        engagementTracker.recordInteraction(
            context: .cards,
            item: "hypothesis_\(hypothesis.id)",
            type: .abandon,
            intensity: 0.2  // Dismissed
        )
        
        // Track analytics
        analyticsTracker.track(.cardSwiped(hypothesisId: "\(hypothesis.id)", direction: "left", hesitationTime: 0))
        
        // Send feedback to backend: user disagrees with this insight
        Task {
            await submitFeedback(for: hypothesis, action: "denied")
            removeHypothesis(hypothesis)
        }
    }

    func swipeRight(hypothesis: Hypothesis) {
        // Track engagement before processing
        engagementTracker.recordInteraction(
            context: .cards,
            item: "hypothesis_\(hypothesis.id)",
            type: .complete,
            intensity: 0.8  // Confirmed
        )
        
        // Track analytics
        analyticsTracker.track(.cardSwiped(hypothesisId: "\(hypothesis.id)", direction: "right", hesitationTime: 0))
        
        // Send feedback to backend: user agrees with this insight
        Task {
            await submitFeedback(for: hypothesis, action: "confirmed")
            removeHypothesis(hypothesis)
        }
    }

    func deepSwipeLeft(hypothesis: Hypothesis) {
        // Track high engagement before processing
        engagementTracker.recordInteraction(
            context: .cards,
            item: "hypothesis_\(hypothesis.id)",
            type: .explore,
            intensity: 1.0  // Maximum engagement - wants to explore deeper
        )
        
        // Submit feedback for analytics
        Task {
            await submitFeedback(for: hypothesis, action: "explore_deeper")
            removeHypothesis(hypothesis)
        }
    }
    
    func deepSwipeRight(hypothesis: Hypothesis) {
        // Track high engagement before processing
        engagementTracker.recordInteraction(
            context: .cards,
            item: "hypothesis_\(hypothesis.id)",
            type: .explore,
            intensity: 1.0  // Maximum engagement - wants to explore deeper
        )
        
        // Track analytics
        analyticsTracker.track(.cardWorkshopTriggered(hypothesisId: "\(hypothesis.id)"))
        
        // Submit feedback for analytics
        Task {
            await submitFeedback(for: hypothesis, action: "explore_deeper")
            removeHypothesis(hypothesis)
        }
    }
    
    func recordCardHesitation(hypothesis: Hypothesis, hesitationTime: TimeInterval) {
        engagementTracker.recordCardHesitation(cardId: "\(hypothesis.id)", hesitationTime: hesitationTime)
        analyticsTracker.track(.cardSwiped(hypothesisId: "\(hypothesis.id)", direction: "hesitated", hesitationTime: hesitationTime))
    }
    
    func recordCardReconsideration(hypothesis: Hypothesis, rereadCount: Int) {
        engagementTracker.recordCardReconsideration(cardId: "\(hypothesis.id)", rereadCount: rereadCount)
        analyticsTracker.track(.cardReturned(hypothesisId: "\(hypothesis.id)", returnCount: rereadCount))
    }
    
    private func submitFeedback(for hypothesis: Hypothesis, action: String) async {
        // In a real app, this would send feedback to your backend
        print("Submitting feedback: \(action) for hypothesis \(hypothesis.id)")
        
        // This data helps the AI learn user preferences and improve future hypotheses
        let feedbackData: [String: Any] = [
            "hypothesis_id": hypothesis.id,
            "action": action,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // TODO: Send to backend API
        // await backendClient.submitFeedback(feedbackData)
    }

    private func removeHypothesis(_ hypothesis: Hypothesis) {
        withAnimation(.easeOut(duration: 0.3)) {
            if let index = hypotheses.firstIndex(of: hypothesis) {
                hypotheses.remove(at: index)
            }
        }
        
        // Generate new hypothesis if we're running low
        if hypotheses.count <= 1 {
            Task {
                await generateAdditionalHypotheses()
            }
        }
    }
    
    private func generateAdditionalHypotheses() async {
        // Try intelligent minting first
        let intelligentCards = await intelligentMinter.mintAssumptionCards(limit: 3)
        
        if !intelligentCards.isEmpty {
            withAnimation(.easeIn(duration: 0.3)) {
                hypotheses.append(contentsOf: intelligentCards)
            }
        } else {
            // Fallback to basic generation
            let fallbackCards = createFallbackHypotheses().prefix(2)
            withAnimation(.easeIn(duration: 0.3)) {
                hypotheses.append(contentsOf: fallbackCards)
            }
        }
    }
}