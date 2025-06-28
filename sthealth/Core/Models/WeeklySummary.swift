//
//  WeeklySummary.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import Foundation
import SwiftData

@Model
final class WeeklySummary {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var generatedAt: Date
    
    // Core Metrics
    var totalReflections: Int
    var totalWords: Int
    var averageWordsPerReflection: Int
    var longestReflection: Int
    var totalInsightsGenerated: Int
    var cardsSwipedRight: Int
    var cardsSwipedLeft: Int
    var workshopSessionsCompleted: Int
    
    // Engagement Patterns
    var mostActiveDay: String
    var mostActiveTimeOfDay: String
    var reflectionStreak: Int
    var missedDays: Int
    
    // Emotional Insights
    var primaryEmotionalThemes: [String]
    var emotionalComplexityScore: Double // 0-1 scale
    var emotionalGrowthAreas: [String]
    
    // Cognitive Patterns
    var recurringThemes: [String]
    var emergingPatterns: [String]
    var avoidancePatterns: [String]
    
    // Growth & Progress
    var weeklyGrowthHighlight: String
    var personalBreakthrough: String?
    var challengesIdentified: [String]
    var strengthsReinforced: [String]
    
    // AI-Generated Insights
    var summaryNarrative: String
    var encouragementMessage: String
    var weekAheadPrompt: String
    
    // Visual Data (for charts)
    var dailyReflectionCounts: [Int] // 7 days
    var emotionalJourney: [Double] // 7 days of sentiment
    var engagementScores: [Double] // 7 days of engagement
    
    init(
        weekStartDate: Date,
        weekEndDate: Date
    ) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.generatedAt = Date()
        
        // Initialize with empty/default values
        self.totalReflections = 0
        self.totalWords = 0
        self.averageWordsPerReflection = 0
        self.longestReflection = 0
        self.totalInsightsGenerated = 0
        self.cardsSwipedRight = 0
        self.cardsSwipedLeft = 0
        self.workshopSessionsCompleted = 0
        
        self.mostActiveDay = ""
        self.mostActiveTimeOfDay = ""
        self.reflectionStreak = 0
        self.missedDays = 0
        
        self.primaryEmotionalThemes = []
        self.emotionalComplexityScore = 0.0
        self.emotionalGrowthAreas = []
        
        self.recurringThemes = []
        self.emergingPatterns = []
        self.avoidancePatterns = []
        
        self.weeklyGrowthHighlight = ""
        self.personalBreakthrough = nil
        self.challengesIdentified = []
        self.strengthsReinforced = []
        
        self.summaryNarrative = ""
        self.encouragementMessage = ""
        self.weekAheadPrompt = ""
        
        self.dailyReflectionCounts = Array(repeating: 0, count: 7)
        self.emotionalJourney = Array(repeating: 0.0, count: 7)
        self.engagementScores = Array(repeating: 0.0, count: 7)
    }
}