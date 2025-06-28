//
//  NudgeEngine.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - Nudge Models

enum NudgeType: String, CaseIterable, Codable {
    case patternInterruption = "pattern_interruption"
    case valuesAlignment = "values_alignment"
    case emotionalGranularity = "emotional_granularity"
    case growthOpportunity = "growth_opportunity"
    case gratitudeStrengths = "gratitude_strengths"
}

enum PsychologicalFramework: String, CaseIterable, Codable {
    case cbt = "CBT"
    case dbt = "DBT"
    case act = "ACT"
    case positivepsychology = "positive_psychology"
    case mindfulness = "mindfulness"
}

enum NudgeResponse: String, Codable {
    case acknowledged = "acknowledged"
    case ignored = "ignored"
    case timeout = "timeout"
}

struct Nudge: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: NudgeType
    let framework: PsychologicalFramework
    let deliveryContext: [String: String]
    let generatedAt: Date
    var deliveredAt: Date?
    var response: NudgeResponse?
    var responseTimestamp: Date?
    var effectivenessScore: Double?
    
    init(content: String, type: NudgeType, framework: PsychologicalFramework, context: [String: String] = [:]) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.framework = framework
        self.deliveryContext = context
        self.generatedAt = Date()
        self.deliveredAt = nil
    }
}

// MARK: - Psychological Profile Analysis

struct PsychologicalProfile {
    let emotionalVocabularyComplexity: Double      // 0-1 scale
    let reflectionPatterns: [String: Double]       // topic -> frequency
    let stressIndicators: [String]                 // recent stress signals
    let growthOpportunities: [String]              // areas for development
    let strengths: [String]                        // identified positive patterns
    let avoidanceTopics: [String]                  // consistently avoided themes
    let optimalReceptivityWindows: [Int]           // hours when most receptive
    let currentLifeNarrativeChapter: String       // e.g., "career_transition", "relationship_growth"
}

struct RecentBehaviorAnalysis {
    let lastReflectionSentiment: Double           // -1 to 1
    let engagementDepth: Double                   // how deeply they engage
    let timeSpentInApp: TimeInterval              // recent session length
    let workshopParticipation: Double             // workshop engagement level
    let cardResponsePatterns: [String: Int]       // swipe patterns
    let emotionalState: String                    // inferred current state
    let receptivityLevel: Double                  // how open they seem to insights
}

// MARK: - Nudge Intelligence Engine

@MainActor
final class NudgeEngine: ObservableObject {
    static let shared = NudgeEngine()
    
    @Published var currentNudge: Nudge?
    @Published var isNudgeVisible: Bool = false
    
    private let cognitiveEngine = CognitiveEngine.shared
    private let engagementTracker = EngagementTracker.shared
    private let backendClient = BackendClient.shared
    
    // Nudge delivery constraints
    private let minimumTimeBetweenNudges: TimeInterval = 24 * 60 * 60  // 24 hours
    private let nudgeDisplayDuration: TimeInterval = 5 * 60           // 5 minutes
    
    private var nudgeTimer: Timer?
    private var lastNudgeTime: Date? {
        get { UserDefaults.standard.object(forKey: "lastNudgeTime") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastNudgeTime") }
    }
    
    private init() {}
    
    // MARK: - Main Nudge Logic
    
    func checkForNudgeOpportunity() {
        Task {
            await evaluateAndDeliverNudge()
        }
    }
    
    private func evaluateAndDeliverNudge() async {
        // Check timing constraints
        guard shouldConsiderNudgeDelivery() else { return }
        
        // Analyze user's current psychological state
        let profile = await buildPsychologicalProfile()
        let recentBehavior = await analyzeRecentBehavior()
        
        // Determine if user is psychologically ready
        guard isUserReceptive(profile: profile, behavior: recentBehavior) else { return }
        
        // Generate contextual nudge
        if let nudge = await generateIntelligentNudge(profile: profile, behavior: recentBehavior) {
            await deliverNudge(nudge)
        }
    }
    
    private func shouldConsiderNudgeDelivery() -> Bool {
        guard let lastNudge = lastNudgeTime else { return true }
        return Date().timeIntervalSince(lastNudge) > minimumTimeBetweenNudges
    }
    
    private func isUserReceptive(profile: PsychologicalProfile, behavior: RecentBehaviorAnalysis) -> Bool {
        // Don't nudge during crisis periods
        if behavior.lastReflectionSentiment < -0.7 {
            return false
        }
        
        // Don't nudge if they're clearly avoiding the app
        if behavior.engagementDepth < 0.3 {
            return false
        }
        
        // Check if it's within their optimal receptivity window
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isOptimalTime = profile.optimalReceptivityWindows.contains(currentHour)
        
        // High receptivity or good timing
        return behavior.receptivityLevel > 0.6 || isOptimalTime
    }
    
    // MARK: - Psychological Analysis
    
    private func buildPsychologicalProfile() async -> PsychologicalProfile {
        let _ = engagementTracker.getTopPsychologicalConcepts(limit: 20)
        
        // Mock implementation - in real app, this would analyze reflection content
        return PsychologicalProfile(
            emotionalVocabularyComplexity: 0.7,
            reflectionPatterns: ["work": 0.4, "relationships": 0.3, "self_growth": 0.2, "creativity": 0.1],
            stressIndicators: ["overwhelmed", "anxious", "pressure"],
            growthOpportunities: ["boundaries", "self_compassion", "communication"],
            strengths: ["self_awareness", "resilience", "curiosity"],
            avoidanceTopics: ["conflict", "vulnerability", "family"],
            optimalReceptivityWindows: [9, 10, 19, 20], // 9-10am, 7-8pm
            currentLifeNarrativeChapter: "career_growth_phase"
        )
    }
    
    private func analyzeRecentBehavior() async -> RecentBehaviorAnalysis {
        // Mock implementation - would analyze recent engagement data
        return RecentBehaviorAnalysis(
            lastReflectionSentiment: 0.2,  // Slightly positive
            engagementDepth: 0.7,          // High engagement
            timeSpentInApp: 240,           // 4 minutes
            workshopParticipation: 0.8,    // Active in workshop
            cardResponsePatterns: ["acknowledged": 3, "dismissed": 1],
            emotionalState: "reflective",
            receptivityLevel: 0.8
        )
    }
    
    // MARK: - Intelligent Nudge Generation
    
    private func generateIntelligentNudge(profile: PsychologicalProfile, behavior: RecentBehaviorAnalysis) async -> Nudge? {
        // Determine appropriate nudge type based on user state
        let nudgeType = selectOptimalNudgeType(profile: profile, behavior: behavior)
        let framework = selectPsychologicalFramework(for: nudgeType, profile: profile)
        
        // Generate AI-powered content
        guard let content = await generateNudgeContent(
            type: nudgeType,
            framework: framework,
            profile: profile,
            behavior: behavior
        ) else { return nil }
        
        let context = [
            "user_state": behavior.emotionalState,
            "receptivity": "\(behavior.receptivityLevel)",
            "narrative_chapter": profile.currentLifeNarrativeChapter,
            "engagement_depth": "\(behavior.engagementDepth)"
        ]
        
        return Nudge(content: content, type: nudgeType, framework: framework, context: context)
    }
    
    private func selectOptimalNudgeType(profile: PsychologicalProfile, behavior: RecentBehaviorAnalysis) -> NudgeType {
        // Pattern interruption if stuck in cycles
        if profile.reflectionPatterns.values.max() ?? 0 > 0.6 {
            return .patternInterruption
        }
        
        // Growth opportunity if highly engaged
        if behavior.engagementDepth > 0.7 && behavior.receptivityLevel > 0.7 {
            return .growthOpportunity
        }
        
        // Values alignment if medium engagement
        if behavior.engagementDepth > 0.5 {
            return .valuesAlignment
        }
        
        // Gratitude/strengths if lower energy
        return .gratitudeStrengths
    }
    
    private func selectPsychologicalFramework(for type: NudgeType, profile: PsychologicalProfile) -> PsychologicalFramework {
        switch type {
        case .patternInterruption:
            return .cbt
        case .valuesAlignment:
            return .act
        case .emotionalGranularity:
            return .dbt
        case .growthOpportunity:
            return .positivepsychology
        case .gratitudeStrengths:
            return .positivepsychology
        }
    }
    
    private func generateNudgeContent(type: NudgeType, framework: PsychologicalFramework, profile: PsychologicalProfile, behavior: RecentBehaviorAnalysis) async -> String? {
        
        let systemPrompt = buildSystemPrompt(type: type, framework: framework)
        let userContext = buildUserContext(profile: profile, behavior: behavior)
        
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: userContext)
            ],
            temperature: 0.8,
            max_tokens: 80,
            response_format: nil
        )
        
        guard let response = try? await cognitiveEngine.makeChatRequest(with: requestBody), 
              !response.isEmpty else {
            print("Nudge generation failed, using fallback")
            return getFallbackNudge(type: type)
        }
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func buildSystemPrompt(type: NudgeType, framework: PsychologicalFramework) -> String {
        let basePrompt = "You are an emotionally intelligent nudge generator. Create a gentle, insightful micro-intervention that primes subconscious reflection without demanding action. Use \(framework.rawValue) principles."
        
        switch type {
        case .patternInterruption:
            return basePrompt + " Focus on gently interrupting thought patterns and offering new perspectives. Keep it under 60 characters."
        case .valuesAlignment:
            return basePrompt + " Focus on connecting actions to deeper values and authentic desires. Keep it under 60 characters."
        case .emotionalGranularity:
            return basePrompt + " Focus on emotional nuance and helping distinguish between similar feelings. Keep it under 60 characters."
        case .growthOpportunity:
            return basePrompt + " Focus on highlighting growth edges and expansion opportunities. Keep it under 60 characters."
        case .gratitudeStrengths:
            return basePrompt + " Focus on recognizing existing strengths and moments of gratitude. Keep it under 60 characters."
        }
    }
    
    private func buildUserContext(profile: PsychologicalProfile, behavior: RecentBehaviorAnalysis) -> String {
        let topPattern = profile.reflectionPatterns.max(by: { $0.value < $1.value })?.key ?? "general"
        
        return """
        User's current context:
        - Primary reflection theme: \(topPattern)
        - Emotional state: \(behavior.emotionalState)
        - Recent sentiment: \(behavior.lastReflectionSentiment > 0 ? "positive" : "challenging")
        - Life chapter: \(profile.currentLifeNarrativeChapter)
        - Receptivity level: \(behavior.receptivityLevel)
        
        Generate a subtle, emotionally intelligent nudge that creates a gentle opening for insight.
        """
    }
    
    private func getFallbackNudge(type: NudgeType) -> String {
        switch type {
        case .patternInterruption:
            return "Notice the story you're telling yourself right now..."
        case .valuesAlignment:
            return "What would your most authentic self do in this moment?"
        case .emotionalGranularity:
            return "That feeling has layers. What's beneath the surface?"
        case .growthOpportunity:
            return "You're on the edge of understanding something important."
        case .gratitudeStrengths:
            return "Your growth over the past month has been remarkable."
        }
    }
    
    // MARK: - Nudge Delivery & Management
    
    private func deliverNudge(_ nudge: Nudge) async {
        var deliveredNudge = nudge
        deliveredNudge.deliveredAt = Date()
        
        // Show in app
        currentNudge = deliveredNudge
        withAnimation(AppAnimation.gentle) {
            isNudgeVisible = true
        }
        
        // Track delivery
        engagementTracker.recordInteraction(
            context: .reflection,
            item: "nudge_\(nudge.id.uuidString)",
            type: .view,
            metadata: [
                "type": nudge.type.rawValue,
                "framework": nudge.framework.rawValue
            ]
        )
        
        // Send to backend
        await sendNudgeToBackend(deliveredNudge)
        
        // Schedule auto-dismiss
        startDismissTimer()
        
        // Update timing
        lastNudgeTime = Date()
        
        // Schedule push notification version
        await scheduleNotification(for: nudge)
    }
    
    func acknowledgeNudge() {
        guard var nudge = currentNudge else { return }
        
        nudge.response = .acknowledged
        nudge.responseTimestamp = Date()
        
        // Track acknowledgment
        engagementTracker.recordInteraction(
            context: .reflection,
            item: "nudge_\(nudge.id.uuidString)",
            type: .complete,
            intensity: 1.0,
            metadata: ["response": "acknowledged"]
        )
        
        // Send response to backend
        Task {
            await sendNudgeResponseToBackend(nudge)
        }
        
        dismissNudge()
    }
    
    private func dismissNudge() {
        nudgeTimer?.invalidate()
        nudgeTimer = nil
        
        withAnimation(AppAnimation.gentle) {
            isNudgeVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentNudge = nil
        }
    }
    
    private func startDismissTimer() {
        nudgeTimer?.invalidate()
        nudgeTimer = Timer.scheduledTimer(withTimeInterval: nudgeDisplayDuration, repeats: false) { _ in
            Task { @MainActor in
                if var nudge = self.currentNudge, nudge.response == nil {
                    nudge.response = .timeout
                    nudge.responseTimestamp = Date()
                    
                    // Track timeout
                    self.engagementTracker.recordInteraction(
                        context: .reflection,
                        item: "nudge_\(nudge.id.uuidString)",
                        type: .abandon,
                        intensity: 0.1,
                        metadata: ["response": "timeout"]
                    )
                    
                    await self.sendNudgeResponseToBackend(nudge)
                }
                
                self.dismissNudge()
            }
        }
    }
    
    // MARK: - Push Notifications
    
    private func scheduleNotification(for nudge: Nudge) async {
        let center = UNUserNotificationCenter.current()
        
        // Request permission
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted == true else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "💭 A gentle thought"
        content.body = nudge.content
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "NUDGE"
        
        // Schedule for user's optimal time (next occurrence)
        let profile = await buildPsychologicalProfile()
        let optimalHours = profile.optimalReceptivityWindows
        
        guard let nextOptimalHour = optimalHours.first(where: { hour in
            let calendar = Calendar.current
            if let nextTime = calendar.nextDate(after: Date(), matching: DateComponents(hour: hour), matchingPolicy: .nextTime) {
                return nextTime.timeIntervalSinceNow > 3600 // At least 1 hour from now
            }
            return false
        }) else { return }
        
        let triggerDate = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: nextOptimalHour), matchingPolicy: .nextTime)!
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: "nudge_\(nudge.id.uuidString)", content: content, trigger: trigger)
        
        try? await center.add(request)
    }
    
    // MARK: - Backend Integration
    
    private func sendNudgeToBackend(_ nudge: Nudge) async {
        let payload: [String: Any] = [
            "nudge_id": nudge.id.uuidString,
            "content": nudge.content,
            "type": nudge.type.rawValue,
            "framework": nudge.framework.rawValue,
            "delivery_context": nudge.deliveryContext,
            "generated_at": ISO8601DateFormatter().string(from: nudge.generatedAt),
            "delivered_at": ISO8601DateFormatter().string(from: nudge.deliveredAt ?? Date())
        ]
        
        let dataPoint = DataPointCreate(
            data_type: "nudge_delivery",
            source: "ios_nudge_engine",
            payload: payload
        )
        
        do {
            _ = try await backendClient.submitDataPoints([dataPoint])
        } catch {
            print("Failed to send nudge to backend: \(error)")
        }
    }
    
    private func sendNudgeResponseToBackend(_ nudge: Nudge) async {
        let payload: [String: Any] = [
            "nudge_id": nudge.id.uuidString,
            "response": nudge.response?.rawValue ?? "unknown",
            "response_timestamp": ISO8601DateFormatter().string(from: nudge.responseTimestamp ?? Date()),
            "response_time_seconds": nudge.responseTimestamp?.timeIntervalSince(nudge.deliveredAt ?? Date()) ?? 0
        ]
        
        let dataPoint = DataPointCreate(
            data_type: "nudge_response",
            source: "ios_nudge_engine",
            payload: payload
        )
        
        do {
            _ = try await backendClient.submitDataPoints([dataPoint])
        } catch {
            print("Failed to send nudge response to backend: \(error)")
        }
    }
}

