//
//  WeeklySummaryView.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import SwiftUI
import Charts

struct WeeklySummaryView: View {
    let summary: WeeklySummary
    @Environment(\.dismiss) private var dismiss
    @StateObject private var summaryEngine = WeeklySummaryEngine.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Core Stats
                    statsSection
                    
                    // Emotional Journey Chart
                    emotionalJourneySection
                    
                    // Daily Activity Chart
                    activityChartSection
                    
                    // AI Narrative
                    narrativeSection
                    
                    // Themes & Patterns
                    themesSection
                    
                    // Growth & Challenges
                    growthSection
                    
                    // Week Ahead Prompt
                    weekAheadSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        summaryEngine.markSummaryAsViewed(summary)
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Your Week in Reflection")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)
            
            Text(dateRangeText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondaryText)
        }
        .padding(.top, 8)
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "doc.text.fill",
                    value: "\(summary.totalReflections)",
                    label: "Reflections",
                    color: .primaryAccent
                )
                
                StatCard(
                    icon: "text.word.spacing",
                    value: "\(summary.totalWords)",
                    label: "Words Written",
                    color: .blue
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(summary.reflectionStreak)",
                    label: "Day Streak",
                    color: .orange
                )
                
                StatCard(
                    icon: "sparkles",
                    value: "\(summary.totalInsightsGenerated)",
                    label: "Insights",
                    color: .purple
                )
            }
        }
    }
    
    private var emotionalJourneySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotional Journey")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Chart {
                ForEach(Array(summary.emotionalJourney.enumerated()), id: \.offset) { index, sentiment in
                    LineMark(
                        x: .value("Day", dayName(for: index)),
                        y: .value("Sentiment", sentiment)
                    )
                    .foregroundStyle(Color.primaryAccent)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    AreaMark(
                        x: .value("Day", dayName(for: index)),
                        y: .value("Sentiment", sentiment)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryAccent.opacity(0.3), Color.primaryAccent.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 200)
            .chartYScale(domain: -1...1)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.tertiaryText.opacity(0.3))
                    AxisValueLabel()
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.secondaryBackground)
        .cornerRadius(16)
    }
    
    private var activityChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Activity")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Chart {
                ForEach(Array(summary.dailyReflectionCounts.enumerated()), id: \.offset) { index, count in
                    BarMark(
                        x: .value("Day", dayName(for: index)),
                        y: .value("Reflections", count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryAccent, Color.primaryAccent.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.secondaryBackground)
        .cornerRadius(16)
    }
    
    private var narrativeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Week's Story")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(summary.summaryNarrative)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primaryText)
                .lineSpacing(4)
            
            if !summary.encouragementMessage.isEmpty {
                Text(summary.encouragementMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primaryAccent)
                    .italic()
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.primaryAccent.opacity(0.1), Color.primaryAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Themes & Patterns")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            if !summary.primaryEmotionalThemes.isEmpty {
                ThemeRow(
                    title: "Emotional Themes",
                    items: summary.primaryEmotionalThemes,
                    color: .purple
                )
            }
            
            if !summary.recurringThemes.isEmpty {
                ThemeRow(
                    title: "Recurring Topics",
                    items: summary.recurringThemes,
                    color: .blue
                )
            }
            
            if !summary.emergingPatterns.isEmpty {
                ThemeRow(
                    title: "Emerging Patterns",
                    items: summary.emergingPatterns,
                    color: .green
                )
            }
        }
    }
    
    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Growth Highlight
            if !summary.weeklyGrowthHighlight.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Growth Highlight", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text(summary.weeklyGrowthHighlight)
                        .font(.system(size: 15))
                        .foregroundColor(.primaryText)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Personal Breakthrough
            if let breakthrough = summary.personalBreakthrough {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Breakthrough Moment", systemImage: "star.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.yellow)
                    
                    Text(breakthrough)
                        .font(.system(size: 15))
                        .foregroundColor(.primaryText)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var weekAheadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Looking Ahead")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(summary.weekAheadPrompt)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primaryText)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryAccent, lineWidth: 1)
                )
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Helpers
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: summary.weekStartDate)
        let end = formatter.string(from: summary.weekEndDate)
        return "\(start) - \(end)"
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[index]
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.secondaryBackground)
        .cornerRadius(16)
    }
}

struct ThemeRow: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondaryText)
            
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.15))
                        .cornerRadius(20)
                }
            }
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            self.size = CGSize(width: width, height: y + maxHeight)
        }
    }
}

#Preview {
    WeeklySummaryView(summary: WeeklySummary(
        weekStartDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
        weekEndDate: Date()
    ))
}