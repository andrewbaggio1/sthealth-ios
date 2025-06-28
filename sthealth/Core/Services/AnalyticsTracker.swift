//
//  AnalyticsTracker.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import SwiftUI

// MARK: - Analytics Events
enum AnalyticsEvent {
    // Reflection Events
    case reflectionStarted(method: String)
    case reflectionCompleted(wordCount: Int, duration: TimeInterval, method: String)
    case reflectionDeleted(id: String)
    case voiceRecordingStarted
    case voiceRecordingStopped(duration: TimeInterval)
    case imageAdded
    case imageRemoved
    
    // Card Events
    case cardViewed(hypothesisId: String, position: Int)
    case cardSwiped(hypothesisId: String, direction: String, hesitationTime: TimeInterval)
    case cardReturned(hypothesisId: String, returnCount: Int)
    case cardWorkshopTriggered(hypothesisId: String)
    
    // Nudge Events
    case nudgeShown(nudgeType: String, content: String)
    case nudgeAcknowledged(nudgeType: String, method: String, timeShown: TimeInterval)
    case nudgeIgnored(nudgeType: String, timeShown: TimeInterval)
    case nudgeHearted(nudgeType: String)
    
    // Workshop Events
    case workshopStarted(hypothesisId: String, source: String)
    case workshopMessageSent(sessionId: String, messageLength: Int)
    case workshopCompleted(sessionId: String, duration: TimeInterval, messageCount: Int)
    case workshopAbandoned(sessionId: String, duration: TimeInterval)
    
    // Navigation Events
    case tabChanged(from: String, to: String)
    case profileOpened
    case compassValueAdded(name: String)
    case compassGoalAdded(title: String)
    case compassItemEdited(type: String, id: String)
    case compassItemDeleted(type: String, id: String)
    
    // Session Events
    case appOpened
    case appBackgrounded
    case sessionStarted
    case sessionEnded(duration: TimeInterval)
    
    // Engagement Events
    case dailyStreakUpdated(newStreak: Int)
    case weeklyReviewOpened
    case weeklyReviewCompleted
}

// MARK: - Analytics Tracker
@MainActor
class AnalyticsTracker: ObservableObject {
    static let shared = AnalyticsTracker()
    
    private let backendClient = BackendClient.shared
    private var eventQueue: [AnalyticsEventData] = []
    private var sessionStartTime: Date?
    private var currentSessionId = UUID().uuidString
    
    // Batch settings
    private let batchSize = 50
    private let batchInterval: TimeInterval = 30 // 30 seconds
    private var batchTimer: Timer?
    
    init() {
        setupBatchTimer()
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    func track(_ event: AnalyticsEvent) {
        let eventData = createEventData(for: event)
        eventQueue.append(eventData)
        
        // Send immediately if queue is full
        if eventQueue.count >= batchSize {
            Task {
                await sendBatch()
            }
        }
    }
    
    func startSession() {
        sessionStartTime = Date()
        currentSessionId = UUID().uuidString
        track(.sessionStarted)
    }
    
    func endSession() {
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            track(.sessionEnded(duration: duration))
        }
        
        // Force send any remaining events
        Task {
            await sendBatch()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.sendBatch()
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        startSession()
        track(.appOpened)
    }
    
    @objc private func appWillResignActive() {
        track(.appBackgrounded)
        endSession()
    }
    
    private func createEventData(for event: AnalyticsEvent) -> AnalyticsEventData {
        var eventName: String
        var properties: [String: Any] = [:]
        
        switch event {
        // Reflection Events
        case .reflectionStarted(let method):
            eventName = "reflection_started"
            properties["method"] = method
            
        case .reflectionCompleted(let wordCount, let duration, let method):
            eventName = "reflection_completed"
            properties["word_count"] = wordCount
            properties["duration_seconds"] = duration
            properties["method"] = method
            
        case .reflectionDeleted(let id):
            eventName = "reflection_deleted"
            properties["reflection_id"] = id
            
        case .voiceRecordingStarted:
            eventName = "voice_recording_started"
            
        case .voiceRecordingStopped(let duration):
            eventName = "voice_recording_stopped"
            properties["duration_seconds"] = duration
            
        case .imageAdded:
            eventName = "reflection_image_added"
            
        case .imageRemoved:
            eventName = "reflection_image_removed"
            
        // Card Events
        case .cardViewed(let hypothesisId, let position):
            eventName = "card_viewed"
            properties["hypothesis_id"] = hypothesisId
            properties["position"] = position
            
        case .cardSwiped(let hypothesisId, let direction, let hesitationTime):
            eventName = "card_swiped"
            properties["hypothesis_id"] = hypothesisId
            properties["direction"] = direction
            properties["hesitation_seconds"] = hesitationTime
            
        case .cardReturned(let hypothesisId, let returnCount):
            eventName = "card_returned"
            properties["hypothesis_id"] = hypothesisId
            properties["return_count"] = returnCount
            
        case .cardWorkshopTriggered(let hypothesisId):
            eventName = "card_workshop_triggered"
            properties["hypothesis_id"] = hypothesisId
            
        // Nudge Events
        case .nudgeShown(let nudgeType, let content):
            eventName = "nudge_shown"
            properties["nudge_type"] = nudgeType
            properties["content"] = content
            
        case .nudgeAcknowledged(let nudgeType, let method, let timeShown):
            eventName = "nudge_acknowledged"
            properties["nudge_type"] = nudgeType
            properties["acknowledge_method"] = method
            properties["time_shown_seconds"] = timeShown
            
        case .nudgeIgnored(let nudgeType, let timeShown):
            eventName = "nudge_ignored"
            properties["nudge_type"] = nudgeType
            properties["time_shown_seconds"] = timeShown
            
        case .nudgeHearted(let nudgeType):
            eventName = "nudge_hearted"
            properties["nudge_type"] = nudgeType
            
        // Workshop Events
        case .workshopStarted(let hypothesisId, let source):
            eventName = "workshop_started"
            properties["hypothesis_id"] = hypothesisId
            properties["source"] = source
            
        case .workshopMessageSent(let sessionId, let messageLength):
            eventName = "workshop_message_sent"
            properties["session_id"] = sessionId
            properties["message_length"] = messageLength
            
        case .workshopCompleted(let sessionId, let duration, let messageCount):
            eventName = "workshop_completed"
            properties["session_id"] = sessionId
            properties["duration_seconds"] = duration
            properties["message_count"] = messageCount
            
        case .workshopAbandoned(let sessionId, let duration):
            eventName = "workshop_abandoned"
            properties["session_id"] = sessionId
            properties["duration_seconds"] = duration
            
        // Navigation Events
        case .tabChanged(let from, let to):
            eventName = "tab_changed"
            properties["from_tab"] = from
            properties["to_tab"] = to
            
        case .profileOpened:
            eventName = "profile_opened"
            
        case .compassValueAdded(let name):
            eventName = "compass_value_added"
            properties["value_name"] = name
            
        case .compassGoalAdded(let title):
            eventName = "compass_goal_added"
            properties["goal_title"] = title
            
        case .compassItemEdited(let type, let id):
            eventName = "compass_item_edited"
            properties["item_type"] = type
            properties["item_id"] = id
            
        case .compassItemDeleted(let type, let id):
            eventName = "compass_item_deleted"
            properties["item_type"] = type
            properties["item_id"] = id
            
        // Session Events
        case .appOpened:
            eventName = "app_opened"
            
        case .appBackgrounded:
            eventName = "app_backgrounded"
            
        case .sessionStarted:
            eventName = "session_started"
            
        case .sessionEnded(let duration):
            eventName = "session_ended"
            properties["duration_seconds"] = duration
            
        // Engagement Events
        case .dailyStreakUpdated(let newStreak):
            eventName = "daily_streak_updated"
            properties["new_streak"] = newStreak
            
        case .weeklyReviewOpened:
            eventName = "weekly_review_opened"
            
        case .weeklyReviewCompleted:
            eventName = "weekly_review_completed"
        }
        
        // Add common properties
        properties["session_id"] = currentSessionId
        properties["timestamp"] = ISO8601DateFormatter().string(from: Date())
        properties["platform"] = "ios"
        properties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        
        return AnalyticsEventData(
            event_name: eventName,
            properties: properties,
            timestamp: Date()
        )
    }
    
    private func sendBatch() async {
        guard !eventQueue.isEmpty && backendClient.isAuthenticated else { return }
        
        // Take current batch
        let batchToSend = Array(eventQueue.prefix(batchSize))
        eventQueue.removeFirst(min(batchSize, eventQueue.count))
        
        // Convert to data points
        let dataPoints = batchToSend.map { event in
            DataPointCreate(
                data_type: "analytics",
                source: "app_tracking",
                payload: [
                    "event_name": event.event_name,
                    "properties": event.properties,
                    "timestamp": ISO8601DateFormatter().string(from: event.timestamp)
                ]
            )
        }
        
        do {
            _ = try await backendClient.submitDataPoints(dataPoints)
            print("📊 Analytics batch sent: \(dataPoints.count) events")
        } catch {
            print("❌ Failed to send analytics batch: \(error)")
            // Re-add events to queue for retry
            eventQueue.insert(contentsOf: batchToSend, at: 0)
        }
    }
}

// MARK: - Analytics Event Data
struct AnalyticsEventData {
    let event_name: String
    let properties: [String: Any]
    let timestamp: Date
}

// MARK: - View Modifiers for Tracking
struct TrackableView: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Track view appearance
                AnalyticsTracker.shared.track(.cardViewed(hypothesisId: viewName, position: 0))
            }
    }
}

extension View {
    func trackView(_ name: String) -> some View {
        modifier(TrackableView(viewName: name))
    }
}