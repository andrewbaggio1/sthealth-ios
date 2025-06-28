//
//  IntelligentCardMinter.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import SwiftData

// MARK: - Assumption Categories

enum AssumptionCategory: String, CaseIterable {
    case behavioral = "behavioral"
    case temporal = "temporal"
    case emotional = "emotional"
    case social = "social"
    case cognitive = "cognitive"
    case avoidance = "avoidance"
    case connection = "connection"
}

struct StrictAssumption {
    let category: AssumptionCategory
    let statement: String
    let confidence: Double
    let supportingEvidence: [String]
    let psychologicalFramework: String  // CBT, DBT, etc.
}

// MARK: - Intelligent Card Minter

@MainActor
final class IntelligentCardMinter: ObservableObject {
    static let shared = IntelligentCardMinter()
    
    private let engagementTracker = EngagementTracker.shared
    private let cognitiveEngine = CognitiveEngine.shared
    private let backendClient = BackendClient.shared
    
    // Prevents over-generation
    private var lastMintTime: Date?
    private let minimumMintInterval: TimeInterval = 24 * 60 * 60  // 24 hours
    
    private init() {}
    
    // MARK: - Main Intelligence Logic
    
    func shouldMintNewCards() -> Bool {
        // Never mint too frequently
        if let lastMint = lastMintTime,
           Date().timeIntervalSince(lastMint) < minimumMintInterval {
            return false
        }
        
        return hasSignificantPsychologicalPattern() ||
               hasAttentionDivergence() ||
               hasEngagementSpike() ||
               hasAvoidancePattern() ||
               hasContradictoryEvidence()
    }
    
    func mintAssumptionCards(limit: Int = 8) async -> [Hypothesis] {
        guard shouldMintNewCards() else { return [] }
        
        var assumptions: [StrictAssumption] = []
        
        // Generate different types of assumptions
        assumptions += await generateBehavioralAssumptions()
        assumptions += await generateTemporalAssumptions()
        assumptions += await generateEmotionalAssumptions()
        assumptions += await generateSocialAssumptions()
        assumptions += await generateAvoidanceAssumptions()
        assumptions += await generateConnectionAssumptions()
        
        // Sort by confidence and psychological significance
        let topAssumptions = assumptions
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
        
        // Convert to hypothesis cards
        let hypotheses = topAssumptions.enumerated().map { index, assumption in
            Hypothesis(
                id: Int.random(in: 10000...99999),
                question_text: assumption.statement
            )
        }
        
        lastMintTime = Date()
        
        // Log the minting event
        for (index, assumption) in topAssumptions.enumerated() {
            engagementTracker.recordInteraction(
                context: .cards,
                item: "minted_assumption_\(index)",
                type: .view,
                metadata: [
                    "category": assumption.category.rawValue,
                    "confidence": "\(assumption.confidence)",
                    "framework": assumption.psychologicalFramework
                ]
            )
        }
        
        return Array(hypotheses)
    }
    
    // MARK: - Assumption Generators
    
    private func generateBehavioralAssumptions() async -> [StrictAssumption] {
        var assumptions: [StrictAssumption] = []
        
        // Analyze productivity patterns
        if await hasProductivityAnxietyPattern() {
            assumptions.append(StrictAssumption(
                category: .behavioral,
                statement: "You use productivity as a way to avoid dealing with uncomfortable emotions.",
                confidence: 0.85,
                supportingEvidence: ["High productivity mentions during emotional periods", "Workshop avoidance of emotional tools"],
                psychologicalFramework: "CBT - Behavioral Avoidance"
            ))
        }
        
        // Analyze social patterns
        if await hasSocialMediaAnxietyPattern() {
            assumptions.append(StrictAssumption(
                category: .behavioral,
                statement: "Social media consistently triggers your anxiety, but you keep using it as emotional regulation.",
                confidence: 0.80,
                supportingEvidence: ["Anxiety reflections after social mentions", "Repeated social media engagement despite negative outcomes"],
                psychologicalFramework: "DBT - Distress Tolerance"
            ))
        }
        
        return assumptions
    }
    
    private func generateTemporalAssumptions() async -> [StrictAssumption] {
        var assumptions: [StrictAssumption] = []
        
        // Check morning vs evening patterns
        if await hasMorningEveningMoodDifference() {
            assumptions.append(StrictAssumption(
                category: .temporal,
                statement: "You're naturally more optimistic in the mornings and struggle more in the evenings, but you don't plan your day around this pattern.",
                confidence: 0.75,
                supportingEvidence: ["Morning reflections 60% more positive", "Evening workshop usage spikes"],
                psychologicalFramework: "Chronobiology - Circadian Mood Patterns"
            ))
        }
        
        // Check weekly patterns
        if await hasWeeklyStressPattern() {
            assumptions.append(StrictAssumption(
                category: .temporal,
                statement: "Sundays trigger anticipatory anxiety about the week ahead, but you've never connected this to your Monday mood.",
                confidence: 0.70,
                supportingEvidence: ["Sunday evening reflection negativity", "Monday productivity overcompensation"],
                psychologicalFramework: "CBT - Anticipatory Anxiety"
            ))
        }
        
        return assumptions
    }
    
    private func generateEmotionalAssumptions() async -> [StrictAssumption] {
        var assumptions: [StrictAssumption] = []
        
        // Emotional vocabulary analysis
        if await hasEmotionalVocabularyImbalance() {
            assumptions.append(StrictAssumption(
                category: .emotional,
                statement: "You're much better at describing negative emotions than positive ones, which keeps you focused on what's wrong.",
                confidence: 0.80,
                supportingEvidence: ["5x more complex vocabulary for negative emotions", "Positive reflections use basic words"],
                psychologicalFramework: "Positive Psychology - Emotional Granularity"
            ))
        }
        
        // Self-criticism patterns
        if await hasSelfCriticismPattern() {
            assumptions.append(StrictAssumption(
                category: .emotional,
                statement: "You're significantly harder on yourself than you would be on a friend in the same situation.",
                confidence: 0.85,
                supportingEvidence: ["Self-critical language 3x higher than other-critical", "Workshop time on self-compassion tools"],
                psychologicalFramework: "CBT - Cognitive Distortions"
            ))
        }
        
        return assumptions
    }
    
    private func generateSocialAssumptions() async -> [StrictAssumption] {
        var assumptions: [StrictAssumption] = []
        
        // Relationship avoidance
        if await hasConflictAvoidancePattern() {
            assumptions.append(StrictAssumption(
                category: .social,
                statement: "You avoid difficult conversations and then feel resentful, but you blame the other person for not understanding you.",
                confidence: 0.75,
                supportingEvidence: ["Relationship reflections lack conflict words", "Resentment themes appear after social events"],
                psychologicalFramework: "DBT - Interpersonal Effectiveness"
            ))
        }
        
        // Validation seeking
        if await hasValidationSeekingPattern() {
            assumptions.append(StrictAssumption(
                category: .social,
                statement: "You seek validation through achievements because you don't believe people will like you just for who you are.",
                confidence: 0.70,
                supportingEvidence: ["Achievement mentions correlate with social anxiety", "Workshop focus on self-worth over accomplishments"],
                psychologicalFramework: "Attachment Theory - Validation Seeking"
            ))
        }
        
        return assumptions
    }
    
    private func generateAvoidanceAssumptions() async -> [StrictAssumption] {
        var assumptions: [StrictAssumption] = []
        
        // Workshop avoidance patterns
        let topConcepts = engagementTracker.getTopPsychologicalConcepts()
        let avoidedConcepts = topConcepts.filter { $0.avoidanceScore > 0.6 }
        
        if !avoidedConcepts.isEmpty {
            let avoidedTopics = avoidedConcepts.map { $0.concept }.joined(separator: ", ")
            assumptions.append(StrictAssumption(
                category: .avoidance,
                statement: "You consistently avoid exploring \(avoidedTopics) because it feels too vulnerable, but this is exactly what you need to work on.",
                confidence: 0.80,
                supportingEvidence: ["High abandon rates for these topics", "Physical hesitation patterns detected"],
                psychologicalFramework: "ACT - Psychological Flexibility"
            ))
        }
        
        return assumptions
    }
    
    private func generateConnectionAssumptions() async -> [StrictAssumption] {
        var assumptions: [StrictAssumption] = []
        
        // Hidden connections between different life areas
        if await hasWorkRelationshipConnection() {
            assumptions.append(StrictAssumption(
                category: .connection,
                statement: "Work stress is your main trigger for relationship problems, but you treat them as separate issues.",
                confidence: 0.75,
                supportingEvidence: ["Work stress mentions precede relationship negativity by 1-2 days", "Workshop time split between work and relationship tools"],
                psychologicalFramework: "Systems Theory - Interconnected Life Domains"
            ))
        }
        
        if await hasSleepMoodConnection() {
            assumptions.append(StrictAssumption(
                category: .connection,
                statement: "Poor sleep affects your emotional regulation more than anything else, but you focus on fixing the symptoms instead of your sleep.",
                confidence: 0.85,
                supportingEvidence: ["Sleep mentions correlate with next-day emotional volatility", "Emotional regulation tools used more after poor sleep nights"],
                psychologicalFramework: "Sleep Psychology - Emotional Regulation"
            ))
        }
        
        return assumptions
    }
    
    // MARK: - Pattern Detection Helpers
    
    private func hasSignificantPsychologicalPattern() -> Bool {
        let significantConcepts = engagementTracker.getTopPsychologicalConcepts(limit: 5)
        return significantConcepts.contains { $0.overallSignificance > 0.7 }
    }
    
    private func hasAttentionDivergence() -> Bool {
        return engagementTracker.hasAttentionDivergence()
    }
    
    private func hasEngagementSpike() -> Bool {
        return engagementTracker.hasEngagementSpike()
    }
    
    private func hasAvoidancePattern() -> Bool {
        let topConcepts = engagementTracker.getTopPsychologicalConcepts()
        return topConcepts.contains { $0.avoidanceScore > 0.6 }
    }
    
    private func hasContradictoryEvidence() -> Bool {
        // In a real implementation, this would analyze reflection content vs behavior
        // For now, use engagement patterns as a proxy
        return hasAttentionDivergence()
    }
    
    // MARK: - Specific Pattern Detection (Mock Implementation)
    
    private func hasProductivityAnxietyPattern() async -> Bool {
        // Mock: In real implementation, analyze reflection themes + workshop usage
        return true  // For demo purposes
    }
    
    private func hasSocialMediaAnxietyPattern() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasMorningEveningMoodDifference() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasWeeklyStressPattern() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasEmotionalVocabularyImbalance() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasSelfCriticismPattern() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasConflictAvoidancePattern() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasValidationSeekingPattern() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasWorkRelationshipConnection() async -> Bool {
        return true  // Mock implementation
    }
    
    private func hasSleepMoodConnection() async -> Bool {
        return true  // Mock implementation
    }
}

// MARK: - Integration with Existing System

extension IntelligentCardMinter {
    func getInitialEightCards() -> [Hypothesis] {
        // These are the calibration cards that never regenerate
        return [
            Hypothesis(id: 1, question_text: "You're more creative in the mornings but convince yourself you work better at night."),
            Hypothesis(id: 2, question_text: "Social media consistently triggers your anxiety, but you keep using it as emotional regulation."),
            Hypothesis(id: 3, question_text: "You use productivity as a way to avoid dealing with uncomfortable emotions."),
            Hypothesis(id: 4, question_text: "You're significantly harder on yourself than you would be on a friend in the same situation."),
            Hypothesis(id: 5, question_text: "You avoid difficult conversations and then feel resentful, but you blame the other person for not understanding you."),
            Hypothesis(id: 6, question_text: "Work stress is your main trigger for relationship problems, but you treat them as separate issues."),
            Hypothesis(id: 7, question_text: "You're much better at describing negative emotions than positive ones, which keeps you focused on what's wrong."),
            Hypothesis(id: 8, question_text: "You seek validation through achievements because you don't believe people will like you just for who you are.")
        ]
    }
}