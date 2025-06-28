//
//  WeeklySummaryEngine.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class WeeklySummaryEngine: ObservableObject {
    static let shared = WeeklySummaryEngine()
    
    @Published var hasNewWeeklySummary = false
    @Published var currentWeeklySummary: WeeklySummary?
    
    private let backendClient = BackendClient.shared
    private let analyticsTracker = AnalyticsTracker.shared
    private let nudgeEngine = NudgeEngine.shared
    
    private init() {
        setupWeeklyCheck()
    }
    
    // MARK: - Setup
    
    private func setupWeeklyCheck() {
        // Check if it's Sunday at midnight
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForWeeklySummary()
            }
        }
        
        // Also check on app launch
        Task {
            await checkForWeeklySummary()
        }
    }
    
    // MARK: - Weekly Summary Generation
    
    func checkForWeeklySummary() async {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's Sunday (weekday == 1)
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        
        // Generate summary on Sunday between midnight and 1 AM
        if weekday == 1 && hour == 0 {
            await generateWeeklySummary()
        }
        
        // Also check if we have a summary for this week that hasn't been viewed
        if let lastSummary = try? await fetchLastWeeklySummary() {
            let summaryWeek = calendar.component(.weekOfYear, from: lastSummary.generatedAt)
            let currentWeek = calendar.component(.weekOfYear, from: now)
            
            if summaryWeek == currentWeek && !hasViewedSummary(lastSummary) {
                currentWeeklySummary = lastSummary
                hasNewWeeklySummary = true
                showWeeklySummaryNudge()
            }
        }
        
        // TEMPORARY: Always generate a mock summary for testing
        if currentWeeklySummary == nil {
            await generateMockWeeklySummary()
        }
    }
    
    func generateWeeklySummary() async {
        do {
            // Calculate date range for past week
            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
            
            // Fetch weekly data from backend
            let summaryData = try await backendClient.fetchWeeklySummaryData(
                startDate: startDate,
                endDate: endDate
            )
            
            // Create summary object
            let summary = WeeklySummary(
                weekStartDate: startDate,
                weekEndDate: endDate
            )
            
            // Populate with backend data
            summary.totalReflections = summaryData.totalReflections
            summary.totalWords = summaryData.totalWords
            summary.averageWordsPerReflection = summaryData.totalReflections > 0 ? 
                summaryData.totalWords / summaryData.totalReflections : 0
            summary.longestReflection = summaryData.longestReflection
            summary.totalInsightsGenerated = summaryData.totalInsights
            summary.cardsSwipedRight = summaryData.cardsSwipedRight
            summary.cardsSwipedLeft = summaryData.cardsSwipedLeft
            summary.workshopSessionsCompleted = summaryData.workshopSessions
            
            // Calculate engagement patterns
            summary.mostActiveDay = calculateMostActiveDay(summaryData.dailyActivity)
            summary.mostActiveTimeOfDay = calculateMostActiveTime(summaryData.hourlyActivity)
            summary.reflectionStreak = calculateStreak(summaryData.dailyActivity)
            summary.missedDays = 7 - summaryData.dailyActivity.filter { $0 > 0 }.count
            
            // Get AI-generated insights
            if let aiInsights = try? await generateAIInsights(summaryData) {
                summary.primaryEmotionalThemes = aiInsights.emotionalThemes
                summary.emotionalComplexityScore = aiInsights.emotionalComplexity
                summary.emotionalGrowthAreas = aiInsights.growthAreas
                summary.recurringThemes = aiInsights.recurringThemes
                summary.emergingPatterns = aiInsights.emergingPatterns
                summary.avoidancePatterns = aiInsights.avoidancePatterns
                summary.weeklyGrowthHighlight = aiInsights.growthHighlight
                summary.personalBreakthrough = aiInsights.breakthrough
                summary.challengesIdentified = aiInsights.challenges
                summary.strengthsReinforced = aiInsights.strengths
                summary.summaryNarrative = aiInsights.narrative
                summary.encouragementMessage = aiInsights.encouragement
                summary.weekAheadPrompt = aiInsights.weekAheadPrompt
            }
            
            // Set visual data
            summary.dailyReflectionCounts = summaryData.dailyActivity
            summary.emotionalJourney = summaryData.dailySentiment
            summary.engagementScores = summaryData.dailyEngagement
            
            // Save summary
            currentWeeklySummary = summary
            hasNewWeeklySummary = true
            
            // Store in backend
            try await backendClient.storeWeeklySummary(summary)
            
            // Show nudge notification
            showWeeklySummaryNudge()
            
            // Track analytics
            analyticsTracker.track(.weeklyReviewCompleted)
            
        } catch {
            print("❌ Failed to generate weekly summary: \(error)")
        }
    }
    
    // MARK: - AI Insights Generation
    
    private func generateAIInsights(_ data: WeeklySummaryData) async throws -> AIWeeklyInsights {
        // This would normally call your AI backend
        // For now, returning mock data
        return AIWeeklyInsights(
            emotionalThemes: ["growth", "curiosity", "resilience"],
            emotionalComplexity: 0.75,
            growthAreas: ["emotional expression", "stress management"],
            recurringThemes: ["work-life balance", "relationships", "personal goals"],
            emergingPatterns: ["morning mindfulness", "creative expression"],
            avoidancePatterns: ["conflict discussion", "future planning"],
            growthHighlight: "You've shown remarkable progress in recognizing your emotional patterns this week.",
            breakthrough: "Your reflection on Tuesday about setting boundaries was a significant moment of self-awareness.",
            challenges: ["Managing work stress", "Maintaining consistent sleep schedule"],
            strengths: ["Self-compassion", "Problem-solving", "Emotional awareness"],
            narrative: "This week marked a journey of deeper self-understanding. You navigated challenges with growing awareness and showed particular strength in moments of uncertainty.",
            encouragement: "Your commitment to reflection is creating real change. Each insight builds on the last.",
            weekAheadPrompt: "As you enter the new week, consider: What would it look like to bring the same compassion you show others to yourself?"
        )
    }
    
    // MARK: - Mock Data for Testing
    
    func generateMockWeeklySummary() async {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }
        
        let summary = WeeklySummary(
            weekStartDate: weekStart,
            weekEndDate: weekEnd
        )
        
        // Populate with rich mock data
        summary.totalReflections = 14
        summary.totalWords = 2847
        summary.averageWordsPerReflection = 203
        summary.longestReflection = 523
        summary.totalInsightsGenerated = 28
        summary.cardsSwipedRight = 42
        summary.cardsSwipedLeft = 15
        summary.workshopSessionsCompleted = 3
        
        // Engagement metrics
        summary.mostActiveDay = "Wednesday"
        summary.mostActiveTimeOfDay = "9pm"
        summary.reflectionStreak = 5
        summary.missedDays = 2
        
        // Emotional analysis
        summary.primaryEmotionalThemes = ["growth", "curiosity", "resilience", "vulnerability", "hope"]
        summary.emotionalComplexityScore = 0.78
        summary.emotionalGrowthAreas = ["expressing vulnerability", "managing work stress", "setting boundaries"]
        
        // Content analysis
        summary.recurringThemes = ["work-life balance", "relationships", "personal growth", "creative projects"]
        summary.emergingPatterns = ["morning mindfulness practice", "journaling before bed", "weekend reflection sessions"]
        summary.avoidancePatterns = ["discussing family dynamics", "addressing financial concerns"]
        
        // Growth insights
        summary.weeklyGrowthHighlight = "This week, you showed remarkable progress in recognizing and articulating your emotional needs, particularly in your reflections about workplace boundaries."
        summary.personalBreakthrough = "Your Tuesday evening reflection about the connection between your childhood experiences and current relationship patterns was a profound moment of self-discovery."
        summary.challengesIdentified = ["Managing anxiety during high-pressure meetings", "Maintaining consistent sleep schedule", "Balancing personal time with social obligations"]
        summary.strengthsReinforced = ["Deep self-awareness", "Emotional resilience", "Creative problem-solving", "Compassion for others"]
        
        // AI-generated narrative
        summary.summaryNarrative = "This week represented a significant chapter in your journey of self-discovery. You navigated complex emotions with increasing sophistication, particularly around themes of authenticity and belonging. Your reflections showed a deepening understanding of how past experiences shape present behaviors, while maintaining a forward-looking perspective on growth and change."
        
        summary.encouragementMessage = "Your commitment to daily reflection is creating real, measurable change in how you understand and navigate your inner world. The vulnerability you've shown in exploring difficult topics is a testament to your courage and growth mindset. Remember: every insight, no matter how small, is a step toward the person you're becoming."
        
        summary.weekAheadPrompt = "As you enter this new week, consider: What would it feel like to approach challenging conversations with the same curiosity you bring to your reflections? Your growing emotional intelligence is a superpower waiting to be fully expressed."
        
        // Visual data for charts
        summary.dailyReflectionCounts = [2, 3, 1, 4, 2, 1, 1] // Sun-Sat
        summary.emotionalJourney = [0.3, 0.5, -0.2, 0.7, 0.4, 0.1, 0.6] // Sentiment scores
        summary.engagementScores = [0.8, 0.9, 0.5, 1.0, 0.7, 0.4, 0.6] // Engagement levels
        
        // Set the summary
        currentWeeklySummary = summary
        hasNewWeeklySummary = true
        
        // Show nudge
        showWeeklySummaryNudge()
        
        print("📊 Mock weekly summary generated for testing")
    }
    
    // MARK: - Helper Methods
    
    private func calculateMostActiveDay(_ dailyActivity: [Int]) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let maxIndex = dailyActivity.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return days[maxIndex]
    }
    
    private func calculateMostActiveTime(_ hourlyActivity: [String: Int]) -> String {
        let sortedTimes = hourlyActivity.sorted { $0.value > $1.value }
        if let topTime = sortedTimes.first {
            let hour = Int(topTime.key) ?? 12
            if hour < 12 {
                return "\(hour == 0 ? 12 : hour)am"
            } else {
                return "\(hour == 12 ? 12 : hour - 12)pm"
            }
        }
        return "evening"
    }
    
    private func calculateStreak(_ dailyActivity: [Int]) -> Int {
        var streak = 0
        for activity in dailyActivity.reversed() {
            if activity > 0 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    private func hasViewedSummary(_ summary: WeeklySummary) -> Bool {
        // Check UserDefaults for viewed summaries
        let viewedSummaries = UserDefaults.standard.stringArray(forKey: "viewedWeeklySummaries") ?? []
        return viewedSummaries.contains(summary.id.uuidString)
    }
    
    func markSummaryAsViewed(_ summary: WeeklySummary) {
        var viewedSummaries = UserDefaults.standard.stringArray(forKey: "viewedWeeklySummaries") ?? []
        if !viewedSummaries.contains(summary.id.uuidString) {
            viewedSummaries.append(summary.id.uuidString)
            UserDefaults.standard.set(viewedSummaries, forKey: "viewedWeeklySummaries")
        }
        hasNewWeeklySummary = false
        analyticsTracker.track(.weeklyReviewOpened)
    }
    
    private func fetchLastWeeklySummary() async throws -> WeeklySummary? {
        // Fetch from backend
        return try await backendClient.fetchLatestWeeklySummary()
    }
    
    // MARK: - Nudge Integration
    
    private func showWeeklySummaryNudge() {
        // No longer needed - we have a dedicated weekly summary UI component
        // that takes precedence over regular nudges
    }
}

// MARK: - Data Models

struct WeeklySummaryData: Codable {
    let totalReflections: Int
    let totalWords: Int
    let longestReflection: Int
    let totalInsights: Int
    let cardsSwipedRight: Int
    let cardsSwipedLeft: Int
    let workshopSessions: Int
    let dailyActivity: [Int] // 7 days
    let hourlyActivity: [String: Int]
    let dailySentiment: [Double] // 7 days
    let dailyEngagement: [Double] // 7 days
}

struct AIWeeklyInsights {
    let emotionalThemes: [String]
    let emotionalComplexity: Double
    let growthAreas: [String]
    let recurringThemes: [String]
    let emergingPatterns: [String]
    let avoidancePatterns: [String]
    let growthHighlight: String
    let breakthrough: String?
    let challenges: [String]
    let strengths: [String]
    let narrative: String
    let encouragement: String
    let weekAheadPrompt: String
}