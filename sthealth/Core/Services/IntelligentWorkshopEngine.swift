//
//  IntelligentWorkshopEngine.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import SwiftUI

// MARK: - Enhanced Workshop Models

enum WorkshopSessionType: String, CaseIterable, Codable {
    case hypothesisExploration = "hypothesis_exploration"
    case patternAnalysis = "pattern_analysis"
    case emotionalProcessing = "emotional_processing"
    case valuesAlignment = "values_alignment"
    case growthPlanning = "growth_planning"
    case conflictResolution = "conflict_resolution"
}

enum WorkshopResponse: String, Codable {
    case continuing = "continuing"
    case insightReached = "insight_reached"
    case needsBreak = "needs_break"
    case completed = "completed"
    case abandoned = "abandoned"
}

struct IntelligentWorkshopSession {
    let id: UUID
    let type: WorkshopSessionType
    let hypothesis: Hypothesis?
    let userContext: UserPsychologicalContext
    let messages: [IntelligentMessage]
    var currentStep: Int
    let totalEstimatedSteps: Int
    let effectiveness: Double // 0-1 scale
    let startTime: Date
    var endTime: Date?
    var extractedInsight: String?
    
    init(type: WorkshopSessionType, hypothesis: Hypothesis?, context: UserPsychologicalContext) {
        self.id = UUID()
        self.type = type
        self.hypothesis = hypothesis
        self.userContext = context
        self.messages = []
        self.currentStep = 1
        self.totalEstimatedSteps = type.estimatedSteps
        self.effectiveness = 0.0
        self.startTime = Date()
    }
}

struct IntelligentMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
    let therapeuticIntent: TherapeuticIntent?
    let emotionalTone: EmotionalTone
    let engagementScore: Double // How engaged user seems with this message
    
    init(content: String, role: MessageRole, intent: TherapeuticIntent? = nil, tone: EmotionalTone = .supportive) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
        self.therapeuticIntent = intent
        self.emotionalTone = tone
        self.engagementScore = 0.0
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case therapist = "therapist"
    case system = "system"
}

enum TherapeuticIntent: String, CaseIterable, Codable {
    case exploration = "exploration"
    case validation = "validation"
    case challenge = "challenge"
    case reframe = "reframe"
    case insight = "insight"
    case integration = "integration"
    case closure = "closure"
}

enum EmotionalTone: String, CaseIterable, Codable {
    case supportive = "supportive"
    case curious = "curious"
    case challenging = "challenging"
    case empathetic = "empathetic"
    case celebratory = "celebratory"
    case grounding = "grounding"
}

struct UserPsychologicalContext {
    let currentEmotionalState: String
    let recentPatterns: [String]
    let availedTopics: [String]
    let strengths: [String]
    let vulnerabilities: [String]
    let preferredTherapeuticStyle: TherapeuticStyle
    let sessionHistory: [WorkshopSessionSummary]
}

enum TherapeuticStyle: String, CaseIterable, Codable {
    case directAndChallenging = "direct_challenging"
    case gentleAndSupportive = "gentle_supportive"
    case socraticQuestioning = "socratic_questioning"
    case solutionFocused = "solution_focused"
    case narrativeTherapy = "narrative_therapy"
}

struct WorkshopSessionSummary {
    let type: WorkshopSessionType
    let effectiveness: Double
    let keyInsights: [String]
    let userEngagement: Double
    let completionDate: Date
}

// MARK: - Extensions

extension WorkshopSessionType {
    var estimatedSteps: Int {
        switch self {
        case .hypothesisExploration: return 5
        case .patternAnalysis: return 7
        case .emotionalProcessing: return 6
        case .valuesAlignment: return 4
        case .growthPlanning: return 8
        case .conflictResolution: return 6
        }
    }
    
    var description: String {
        switch self {
        case .hypothesisExploration:
            return "Explore and validate a specific insight or assumption"
        case .patternAnalysis:
            return "Identify and understand recurring patterns in your life"
        case .emotionalProcessing:
            return "Process and understand complex emotions"
        case .valuesAlignment:
            return "Align your actions with your deeper values"
        case .growthPlanning:
            return "Create a plan for personal growth and development"
        case .conflictResolution:
            return "Work through internal or external conflicts"
        }
    }
}

// MARK: - Intelligent Workshop Engine

@MainActor
final class IntelligentWorkshopEngine: ObservableObject {
    static let shared = IntelligentWorkshopEngine()
    
    @Published var currentSession: IntelligentWorkshopSession?
    @Published var isSessionActive: Bool = false
    @Published var messages: [IntelligentMessage] = []
    @Published var isProcessing: Bool = false
    @Published var sessionProgress: Double = 0.0
    
    private let cognitiveEngine = CognitiveEngine.shared
    private let engagementTracker = EngagementTracker.shared
    private let backendClient = BackendClient.shared
    
    private var sessionStartTime: Date?
    private var currentMessageStartTime: Date?
    
    private init() {}
    
    // MARK: - Session Management
    
    func startIntelligentSession(from hypothesis: Hypothesis) async {
        let context = await buildUserContext()
        let sessionType = determineOptimalSessionType(for: hypothesis, context: context)
        
        let session = IntelligentWorkshopSession(
            type: sessionType,
            hypothesis: hypothesis,
            context: context
        )
        
        currentSession = session
        isSessionActive = true
        messages = []
        sessionProgress = 0.0
        sessionStartTime = Date()
        
        // Track session start
        engagementTracker.recordInteraction(
            context: .workshop,
            item: "intelligent_session_\(session.id.uuidString)",
            type: .view,
            metadata: [
                "session_type": sessionType.rawValue,
                "hypothesis_id": "\(hypothesis.id)"
            ]
        )
        
        // Generate opening message
        await generateOpeningMessage(for: session)
    }
    
    func sendMessage(_ content: String) async {
        guard let session = currentSession else { return }
        
        // Record message timing
        let messageTime = currentMessageStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Add user message
        let userMessage = IntelligentMessage(content: content, role: .user)
        messages.append(userMessage)
        
        // Track user engagement
        engagementTracker.recordInteraction(
            context: .workshop,
            item: "session_message_\(userMessage.id.uuidString)",
            type: .complete,
            duration: messageTime,
            intensity: calculateMessageEngagement(content),
            metadata: [
                "message_length": "\(content.count)",
                "session_step": "\(session.currentStep)"
            ]
        )
        
        isProcessing = true
        
        // Generate AI response
        await generateIntelligentResponse(for: session, userMessage: userMessage)
        
        isProcessing = false
        currentMessageStartTime = Date()
    }
    
    func commitSession() async -> String? {
        guard let session = currentSession else { return nil }
        
        // Calculate session effectiveness
        let effectiveness = await calculateSessionEffectiveness(session)
        
        // Extract key insights
        let insights = await extractSessionInsights(session)
        
        // Track session completion
        let sessionDuration = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        engagementTracker.recordInteraction(
            context: .workshop,
            item: "intelligent_session_\(session.id.uuidString)",
            type: .complete,
            duration: sessionDuration,
            intensity: effectiveness,
            metadata: [
                "insights_count": "\(insights.count)",
                "message_count": "\(messages.count)",
                "completion_step": "\(session.currentStep)"
            ]
        )
        
        // Send to backend
        await submitSessionToBackend(session, insights: insights, effectiveness: effectiveness)
        
        // Clean up
        endSession()
        
        return insights.first // Return primary insight
    }
    
    func endSession() {
        currentSession = nil
        isSessionActive = false
        messages = []
        sessionProgress = 0.0
        sessionStartTime = nil
        currentMessageStartTime = nil
    }
    
    // MARK: - Intelligent Analysis
    
    private func buildUserContext() async -> UserPsychologicalContext {
        let _ = engagementTracker.getTopPsychologicalConcepts(limit: 10)
        
        // Mock implementation - in real app would analyze comprehensive user data
        return UserPsychologicalContext(
            currentEmotionalState: "reflective",
            recentPatterns: ["work_stress", "relationship_growth", "creative_exploration"],
            availedTopics: ["family_conflict", "vulnerability", "failure"],
            strengths: ["self_awareness", "curiosity", "resilience"],
            vulnerabilities: ["perfectionism", "people_pleasing", "overthinking"],
            preferredTherapeuticStyle: .gentleAndSupportive,
            sessionHistory: []
        )
    }
    
    private func determineOptimalSessionType(for hypothesis: Hypothesis, context: UserPsychologicalContext) -> WorkshopSessionType {
        let questionText = hypothesis.question_text.lowercased()
        
        // Analyze hypothesis content to determine best session type
        if questionText.contains("pattern") || questionText.contains("always") || questionText.contains("repeatedly") {
            return .patternAnalysis
        } else if questionText.contains("feel") || questionText.contains("emotion") || questionText.contains("mood") {
            return .emotionalProcessing
        } else if questionText.contains("value") || questionText.contains("important") || questionText.contains("matter") {
            return .valuesAlignment
        } else if questionText.contains("conflict") || questionText.contains("tension") || questionText.contains("struggle") {
            return .conflictResolution
        } else if questionText.contains("growth") || questionText.contains("change") || questionText.contains("develop") {
            return .growthPlanning
        } else {
            return .hypothesisExploration
        }
    }
    
    private func calculateMessageEngagement(_ content: String) -> Double {
        let wordCount = content.split(separator: " ").count
        let hasEmotionalWords = content.localizedCaseInsensitiveContains("feel") || 
                               content.localizedCaseInsensitiveContains("think") ||
                               content.localizedCaseInsensitiveContains("realize")
        
        var engagement = min(1.0, Double(wordCount) / 20.0) // 20 words = full engagement
        
        if hasEmotionalWords {
            engagement += 0.2
        }
        
        return min(1.0, engagement)
    }
    
    // MARK: - AI Response Generation
    
    private func generateOpeningMessage(for session: IntelligentWorkshopSession) async {
        let systemPrompt = buildTherapistSystemPrompt(for: session)
        let openingPrompt = buildOpeningPrompt(for: session)
        
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: openingPrompt)
            ],
            temperature: 0.7,
            max_tokens: 150,
            response_format: nil
        )
        
        if let response = try? await cognitiveEngine.makeChatRequest(with: requestBody) {
            let therapistMessage = IntelligentMessage(
                content: response,
                role: .therapist,
                intent: .exploration,
                tone: .supportive
            )
            messages.append(therapistMessage)
        }
        
        currentMessageStartTime = Date()
    }
    
    private func generateIntelligentResponse(for session: IntelligentWorkshopSession, userMessage: IntelligentMessage) async {
        let systemPrompt = buildTherapistSystemPrompt(for: session)
        let contextPrompt = buildContextualPrompt(for: session, userMessage: userMessage)
        
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: contextPrompt)
            ],
            temperature: 0.7,
            max_tokens: 200,
            response_format: nil
        )
        
        if let response = try? await cognitiveEngine.makeChatRequest(with: requestBody) {
            let intent = determineTherapeuticIntent(for: session, step: session.currentStep)
            let tone = determineTone(for: userMessage.content, context: session.userContext)
            
            let therapistMessage = IntelligentMessage(
                content: response,
                role: .therapist,
                intent: intent,
                tone: tone
            )
            messages.append(therapistMessage)
            
            // Update session progress
            updateSessionProgress()
        }
    }
    
    private func buildTherapistSystemPrompt(for session: IntelligentWorkshopSession) -> String {
        let basePrompt = """
        You are an exceptionally skilled and emotionally intelligent therapist conducting a \(session.type.description.lowercased()) session. 
        
        User's psychological context:
        - Current emotional state: \(session.userContext.currentEmotionalState)
        - Recent patterns: \(session.userContext.recentPatterns.joined(separator: ", "))
        - Strengths: \(session.userContext.strengths.joined(separator: ", "))
        - Preferred style: \(session.userContext.preferredTherapeuticStyle.rawValue)
        
        Your approach should be:
        - Professionally warm and genuinely curious
        - Adapted to their preferred therapeutic style
        - Focused on helping them reach genuine insights
        - Respectful of their emotional state and boundaries
        
        Session goal: \(session.type.description)
        """
        
        if let hypothesis = session.hypothesis {
            return basePrompt + "\n\nSpecific focus: Exploring the assumption '\(hypothesis.question_text)'"
        }
        
        return basePrompt
    }
    
    private func buildOpeningPrompt(for session: IntelligentWorkshopSession) -> String {
        if let hypothesis = session.hypothesis {
            return """
            Start a therapeutic session to explore this assumption about the user: "\(hypothesis.question_text)"
            
            Create a warm, engaging opening that:
            1. Acknowledges their willingness to explore this
            2. Sets a collaborative tone
            3. Begins with an open-ended question that invites their perspective
            
            Keep it under 150 characters and make it feel natural, not clinical.
            """
        } else {
            return "Create a warm opening for a \(session.type.rawValue) therapeutic session. Be engaging and start with curiosity about their current experience."
        }
    }
    
    private func buildContextualPrompt(for session: IntelligentWorkshopSession, userMessage: IntelligentMessage) -> String {
        let conversationContext = messages.map { msg in
            "\(msg.role.rawValue): \(msg.content)"
        }.joined(separator: "\n")
        
        return """
        Current conversation:
        \(conversationContext)
        
        The user just said: "\(userMessage.content)"
        
        Session progress: Step \(session.currentStep) of \(session.totalEstimatedSteps)
        Current therapeutic intent: \(determineTherapeuticIntent(for: session, step: session.currentStep).rawValue)
        
        Generate your response as a skilled therapist. Be genuinely helpful while moving the session toward meaningful insight.
        """
    }
    
    private func determineTherapeuticIntent(for session: IntelligentWorkshopSession, step: Int) -> TherapeuticIntent {
        let progressRatio = Double(step) / Double(session.totalEstimatedSteps)
        
        switch progressRatio {
        case 0.0..<0.3:
            return .exploration
        case 0.3..<0.5:
            return .validation
        case 0.5..<0.7:
            return .challenge
        case 0.7..<0.9:
            return .insight
        default:
            return .integration
        }
    }
    
    private func determineTone(for userContent: String, context: UserPsychologicalContext) -> EmotionalTone {
        if userContent.localizedCaseInsensitiveContains("confused") || userContent.localizedCaseInsensitiveContains("don't know") {
            return .supportive
        } else if userContent.localizedCaseInsensitiveContains("realize") || userContent.localizedCaseInsensitiveContains("understand") {
            return .celebratory
        } else if userContent.localizedCaseInsensitiveContains("difficult") || userContent.localizedCaseInsensitiveContains("hard") {
            return .empathetic
        } else {
            return .curious
        }
    }
    
    private func updateSessionProgress() {
        guard let session = currentSession else { return }
        guard session.totalEstimatedSteps > 0 else { return }
        
        sessionProgress = min(1.0, max(0.0, Double(session.currentStep) / Double(session.totalEstimatedSteps)))
        
        // Update session step
        currentSession?.currentStep += 1
    }
    
    // MARK: - Session Analysis
    
    private func calculateSessionEffectiveness(_ session: IntelligentWorkshopSession) async -> Double {
        let averageEngagement = messages.compactMap { message in
            message.role == .user ? message.engagementScore : nil
        }.reduce(0, +) / Double(messages.filter { $0.role == .user }.count)
        
        let completionRatio = min(1.0, Double(session.currentStep) / Double(session.totalEstimatedSteps))
        
        return (averageEngagement * 0.7) + (completionRatio * 0.3)
    }
    
    private func extractSessionInsights(_ session: IntelligentWorkshopSession) async -> [String] {
        let conversationText = messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
        
        let systemPrompt = """
        You are an expert at extracting therapeutic insights from session transcripts. 
        Analyze this conversation and identify the 1-3 most important insights or realizations the user had.
        Format each insight as a clear, actionable statement in first person (as if the user is saying it).
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: conversationText)
            ],
            temperature: 0.3,
            max_tokens: 200,
            response_format: nil
        )
        
        if let response = try? await cognitiveEngine.makeChatRequest(with: requestBody) {
            return response.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        return ["I gained valuable self-awareness through this conversation."]
    }
    
    // MARK: - Backend Integration
    
    private func submitSessionToBackend(_ session: IntelligentWorkshopSession, insights: [String], effectiveness: Double) async {
        let payload: [String: Any] = [
            "session_id": session.id.uuidString,
            "session_type": session.type.rawValue,
            "hypothesis_id": session.hypothesis?.id ?? 0,
            "message_count": messages.count,
            "duration_seconds": sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0,
            "effectiveness_score": effectiveness,
            "insights": insights,
            "user_engagement": messages.filter { $0.role == .user }.map { $0.engagementScore },
            "therapeutic_progression": messages.compactMap { $0.therapeuticIntent?.rawValue }
        ]
        
        let dataPoint = DataPointCreate(
            data_type: "intelligent_workshop_session",
            source: "ios_workshop_engine",
            payload: payload
        )
        
        do {
            _ = try await backendClient.submitDataPoints([dataPoint])
        } catch {
            print("Failed to submit workshop session to backend: \(error)")
        }
    }
}