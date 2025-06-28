//
//  EngagementTracker.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import Combine

// MARK: - Engagement Types

enum AppContext: String, Codable {
    case reflection, workshop, cognitiveAtlas, cards, profile, onboarding
}

enum InteractionType: String, Codable {
    case view, focus, explore, hesitate, reconsider, abandon, complete, revisit
}

struct EngagementEvent: Codable {
    let id: UUID
    let timestamp: Date
    let context: AppContext
    let itemIdentifier: String  // e.g. "hypothesis_123", "neural_pathway_xyz", "reflection_456"
    let interactionType: InteractionType
    let duration: TimeInterval
    let intensity: Double  // 0.0 - 1.0 scale
    let metadata: [String: String]?
    
    init(context: AppContext, item: String, type: InteractionType, duration: TimeInterval, intensity: Double = 0.5, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.context = context
        self.itemIdentifier = item
        self.interactionType = type
        self.duration = duration
        self.intensity = intensity
        self.metadata = metadata
    }
}

// MARK: - Psychological Significance Calculator

struct PsychologicalSignificance {
    let concept: String
    let attentionScore: Double      // How much time/focus they give it
    let emotionalIntensity: Double  // How emotionally charged their interaction is
    let consistencyScore: Double    // How consistently they return to it
    let avoidanceScore: Double      // How much they seem to avoid it
    let overallSignificance: Double
    
    init(concept: String, events: [EngagementEvent]) {
        self.concept = concept
        
        // Calculate attention score
        let totalTime = events.reduce(0) { $0 + $1.duration }
        let averageIntensity = events.isEmpty ? 0 : events.reduce(0) { $0 + $1.intensity } / Double(events.count)
        self.attentionScore = min(1.0, totalTime / 300.0) * averageIntensity  // 5 minutes = max attention
        
        // Calculate emotional intensity (based on interaction types)
        let emotionalEvents = events.filter { $0.interactionType == .hesitate || $0.interactionType == .reconsider }
        self.emotionalIntensity = min(1.0, Double(emotionalEvents.count) / 3.0)
        
        // Calculate consistency (return visits)
        let uniqueDays = Set(events.map { Calendar.current.startOfDay(for: $0.timestamp) })
        self.consistencyScore = min(1.0, Double(uniqueDays.count) / 7.0)  // 7 days = max consistency
        
        // Calculate avoidance (quick abandons)
        let abandons = events.filter { $0.interactionType == .abandon && $0.duration < 5.0 }
        self.avoidanceScore = min(1.0, Double(abandons.count) / 3.0)
        
        // Overall significance calculation
        self.overallSignificance = (attentionScore * 0.4) + 
                                  (emotionalIntensity * 0.3) + 
                                  (consistencyScore * 0.2) + 
                                  (avoidanceScore * 0.1)
    }
}

// MARK: - Engagement Tracker

@MainActor
final class EngagementTracker: ObservableObject {
    static let shared = EngagementTracker()
    
    @Published private var engagementEvents: [EngagementEvent] = []
    private var currentFocusStartTime: [String: Date] = [:]
    private let backendClient = BackendClient.shared
    
    private init() {
        loadStoredEvents()
    }
    
    // MARK: - Event Recording
    
    func startFocus(on item: String, context: AppContext) {
        currentFocusStartTime[item] = Date()
    }
    
    func endFocus(on item: String, context: AppContext, intensity: Double = 0.5) {
        guard let startTime = currentFocusStartTime[item] else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        let event = EngagementEvent(
            context: context,
            item: item,
            type: .focus,
            duration: duration,
            intensity: intensity
        )
        
        recordEvent(event)
        currentFocusStartTime.removeValue(forKey: item)
    }
    
    func recordInteraction(context: AppContext, item: String, type: InteractionType, duration: TimeInterval = 0, intensity: Double = 0.5, metadata: [String: String]? = nil) {
        let event = EngagementEvent(
            context: context,
            item: item,
            type: type,
            duration: duration,
            intensity: intensity,
            metadata: metadata
        )
        
        recordEvent(event)
    }
    
    func recordCardHesitation(cardId: String, hesitationTime: TimeInterval) {
        recordInteraction(
            context: .cards,
            item: "hypothesis_\(cardId)",
            type: .hesitate,
            duration: hesitationTime,
            intensity: min(1.0, hesitationTime / 10.0)  // 10 seconds = max intensity
        )
    }
    
    func recordCardReconsideration(cardId: String, rereadCount: Int) {
        recordInteraction(
            context: .cards,
            item: "hypothesis_\(cardId)",
            type: .reconsider,
            intensity: min(1.0, Double(rereadCount) / 3.0),
            metadata: ["reread_count": "\(rereadCount)"]
        )
    }
    
    private func recordEvent(_ event: EngagementEvent) {
        engagementEvents.append(event)
        saveEvents()
        
        // Send to backend for AI analysis
        Task {
            await sendEventToBackend(event)
        }
    }
    
    // MARK: - Psychological Analysis
    
    func calculateSignificance(for concept: String) -> PsychologicalSignificance {
        let relevantEvents = engagementEvents.filter { event in
            event.itemIdentifier.contains(concept.lowercased()) ||
            event.metadata?.values.contains { $0.lowercased().contains(concept.lowercased()) } == true
        }
        
        return PsychologicalSignificance(concept: concept, events: relevantEvents)
    }
    
    func getTopPsychologicalConcepts(limit: Int = 10) -> [PsychologicalSignificance] {
        // Extract all unique concepts from events
        let allConcepts = Set(engagementEvents.compactMap { event in
            // Extract concept from item identifier
            if event.itemIdentifier.hasPrefix("hypothesis_") {
                return "hypothesis"
            } else if event.itemIdentifier.hasPrefix("neural_pathway_") {
                return event.itemIdentifier.replacingOccurrences(of: "neural_pathway_", with: "")
            } else if event.itemIdentifier.hasPrefix("workshop_tool_") {
                return event.itemIdentifier.replacingOccurrences(of: "workshop_tool_", with: "")
            } else {
                return event.itemIdentifier
            }
        })
        
        return allConcepts
            .map { calculateSignificance(for: $0) }
            .sorted { $0.overallSignificance > $1.overallSignificance }
            .prefix(limit)
            .map { $0 }
    }
    
    func hasAttentionDivergence() -> Bool {
        // Compare reflection themes vs workshop/atlas focus
        let reflectionEvents = engagementEvents.filter { $0.context == .reflection }
        let explorationEvents = engagementEvents.filter { $0.context == .workshop || $0.context == .cognitiveAtlas }
        
        // In a real implementation, you'd analyze the semantic content
        // For now, check if they're spending significantly more time exploring concepts
        // they don't explicitly reflect about
        let reflectionTime = reflectionEvents.reduce(0) { $0 + $1.duration }
        let explorationTime = explorationEvents.reduce(0) { $0 + $1.duration }
        
        return explorationTime > reflectionTime * 1.5  // 50% more time exploring than reflecting
    }
    
    func hasEngagementSpike(threshold: Double = 2.0) -> Bool {
        // Check if recent engagement is significantly higher than average
        let recentEvents = engagementEvents.filter { 
            $0.timestamp > Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        }
        
        let allTimeAverage = engagementEvents.isEmpty ? 0 : 
            engagementEvents.reduce(0) { $0 + $1.duration } / Double(engagementEvents.count)
        
        let recentAverage = recentEvents.isEmpty ? 0 :
            recentEvents.reduce(0) { $0 + $1.duration } / Double(recentEvents.count)
        
        return recentAverage > allTimeAverage * threshold
    }
    
    // MARK: - Data Persistence
    
    private func loadStoredEvents() {
        if let data = UserDefaults.standard.data(forKey: "engagementEvents"),
           let events = try? JSONDecoder().decode([EngagementEvent].self, from: data) {
            engagementEvents = events
        }
    }
    
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(engagementEvents) {
            UserDefaults.standard.set(data, forKey: "engagementEvents")
        }
    }
    
    private func sendEventToBackend(_ event: EngagementEvent) async {
        // Convert engagement event to DataPoint for backend
        let payload: [String: Any] = [
            "event_id": event.id.uuidString,
            "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
            "context": event.context.rawValue,
            "item_identifier": event.itemIdentifier,
            "interaction_type": event.interactionType.rawValue,
            "duration": event.duration,
            "intensity": event.intensity,
            "metadata": event.metadata ?? [:]
        ]
        
        let dataPoint = DataPointCreate(
            data_type: "engagement_event",
            source: "ios_app",
            payload: payload
        )
        
        do {
            _ = try await backendClient.submitDataPoints([dataPoint])
        } catch {
            print("Failed to send engagement event to backend: \(error)")
        }
    }
    
    func clearAllData() {
        engagementEvents.removeAll()
        currentFocusStartTime.removeAll()
        UserDefaults.standard.removeObject(forKey: "engagementEvents")
    }
}

// MARK: - Convenience Extensions

extension EngagementTracker {
    func trackWorkshopToolUsage(toolName: String, duration: TimeInterval, completed: Bool) {
        recordInteraction(
            context: .workshop,
            item: "workshop_tool_\(toolName)",
            type: completed ? .complete : .abandon,
            duration: duration,
            intensity: completed ? 1.0 : 0.3
        )
    }
    
    func trackNeuralPathwayExploration(pathwayId: String, duration: TimeInterval, depth: Int) {
        recordInteraction(
            context: .cognitiveAtlas,
            item: "neural_pathway_\(pathwayId)",
            type: .explore,
            duration: duration,
            intensity: min(1.0, Double(depth) / 5.0),  // 5 levels deep = max intensity
            metadata: ["exploration_depth": "\(depth)"]
        )
    }
    
    func trackReflectionEntry(reflectionId: String, wordCount: Int, duration: TimeInterval, inputMethod: String) {
        recordInteraction(
            context: .reflection,
            item: "reflection_\(reflectionId)",
            type: .complete,
            duration: duration,
            intensity: min(1.0, Double(wordCount) / 100.0),  // 100 words = max intensity
            metadata: [
                "word_count": "\(wordCount)",
                "input_method": inputMethod
            ]
        )
    }
}