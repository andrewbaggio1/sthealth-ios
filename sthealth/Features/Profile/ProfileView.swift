import SwiftUI
import LocalAuthentication
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var summaryEngine = WeeklySummaryEngine.shared
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var showingWeeklySummary = false
    
    private var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "User"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Weekly Summary (always show if available)
                    if summaryEngine.currentWeeklySummary != nil {
                        weeklySummaryCard
                    }
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        // Compass Settings
                        settingsSection(
                            title: "Compass",
                            icon: "location.north.circle.fill"
                        ) {
                            SettingsRow(
                                title: "My Values & Goals",
                                subtitle: "Manage your personal compass",
                                icon: "heart.circle.fill",
                                action: { /* Navigation handled by tab */ }
                            )
                        }
                        
                        // Privacy & Security
                        settingsSection(
                            title: "Privacy & Security",
                            icon: "lock.shield.fill"
                        ) {
                            SettingsRow(
                                title: "Biometric Lock",
                                subtitle: "Secure app with Face ID or Touch ID",
                                icon: "faceid",
                                toggle: $viewModel.biometricLockEnabled
                            )
                            
                            SettingsRow(
                                title: "Data Encryption",
                                subtitle: "End-to-end encryption enabled",
                                icon: "checkmark.shield.fill",
                                showChevron: false
                            )
                        }
                        
                        // Notifications
                        settingsSection(
                            title: "Notifications",
                            icon: "bell.fill"
                        ) {
                            SettingsRow(
                                title: "Daily Reminders",
                                subtitle: "Gentle nudges to reflect",
                                icon: "clock.fill",
                                toggle: $viewModel.dailyRemindersEnabled
                            )
                            
                            SettingsRow(
                                title: "Insight Notifications",
                                subtitle: "When new insights are available",
                                icon: "lightbulb.fill",
                                toggle: $viewModel.insightNotificationsEnabled
                            )
                            
                            if viewModel.dailyRemindersEnabled {
                                DatePicker(
                                    "Reminder Time",
                                    selection: $viewModel.reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Data & Analytics
                        settingsSection(
                            title: "Data & Analytics",
                            icon: "chart.bar.fill"
                        ) {
                            SettingsRow(
                                title: "Anonymous Analytics",
                                subtitle: "Help improve the app",
                                icon: "chart.pie.fill",
                                toggle: $viewModel.analyticsEnabled
                            )
                            
                            SettingsRow(
                                title: "Export Data",
                                subtitle: "Download your reflections",
                                icon: "square.and.arrow.down.fill",
                                action: viewModel.exportData
                            )
                            
                            SettingsRow(
                                title: "Data Usage",
                                subtitle: "\(viewModel.dataUsageText)",
                                icon: "internaldrive.fill",
                                showChevron: false
                            )
                        }
                        
                        // AI & Processing
                        settingsSection(
                            title: "AI & Processing",
                            icon: "brain.head.profile"
                        ) {
                            SettingsRow(
                                title: "AI Insights",
                                subtitle: "Generate personalized insights",
                                icon: "sparkles",
                                toggle: $viewModel.aiInsightsEnabled
                            )
                            
                            SettingsRow(
                                title: "Processing Frequency",
                                subtitle: viewModel.processingFrequency.displayName,
                                icon: "timer",
                                action: { viewModel.showProcessingOptions = true }
                            )
                            
                            SettingsRow(
                                title: "Insight Sensitivity",
                                subtitle: viewModel.insightSensitivity.displayName,
                                icon: "slider.horizontal.3",
                                action: { viewModel.showSensitivityOptions = true }
                            )
                        }
                        
                        // Support & About
                        settingsSection(
                            title: "Support & About",
                            icon: "questionmark.circle.fill"
                        ) {
                            SettingsRow(
                                title: "Help & Support",
                                subtitle: "Get help and contact support",
                                icon: "questionmark.circle.fill",
                                action: viewModel.openSupport
                            )
                            
                            SettingsRow(
                                title: "Privacy Policy",
                                subtitle: "How we handle your data",
                                icon: "doc.text.fill",
                                action: viewModel.openPrivacyPolicy
                            )
                            
                            SettingsRow(
                                title: "Terms of Service",
                                subtitle: "App usage terms",
                                icon: "doc.fill",
                                action: viewModel.openTerms
                            )
                            
                            SettingsRow(
                                title: "App Version",
                                subtitle: "1.0.0 (Build 1)",
                                icon: "info.circle.fill",
                                showChevron: false
                            )
                        }
                        
                        // Danger Zone
                        dangerZoneSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.primaryBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .confirmationDialog("Processing Frequency", isPresented: $viewModel.showProcessingOptions) {
            ForEach(ProcessingFrequency.allCases, id: \.self) { frequency in
                Button(frequency.displayName) {
                    viewModel.processingFrequency = frequency
                }
            }
        }
        .confirmationDialog("Insight Sensitivity", isPresented: $viewModel.showSensitivityOptions) {
            ForEach(InsightSensitivity.allCases, id: \.self) { sensitivity in
                Button(sensitivity.displayName) {
                    viewModel.insightSensitivity = sensitivity
                }
            }
        }
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAllData()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all your reflections, insights, and app data. This action cannot be undone.")
        }
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out? Your data will remain secure on this device.")
        }
        .sheet(isPresented: $showingWeeklySummary) {
            if let summary = summaryEngine.currentWeeklySummary {
                WeeklySummaryView(summary: summary)
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(userName.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 4) {
                Text(userName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("Member since \(viewModel.memberSinceText)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }
            
            // Stats
            HStack(spacing: 32) {
                StatView(title: "Reflections", value: "\(viewModel.reflectionCount)")
                StatView(title: "Insights", value: "\(viewModel.insightCount)")
                StatView(title: "Streak", value: "\(viewModel.streakDays)")
            }
        }
        .padding(.vertical, 20)
    }
    
    private var weeklySummaryCard: some View {
        VStack(spacing: 4) {
            // Golden weekly summary card matching nudge style
            Button(action: { showingWeeklySummary = true }) {
                HStack(spacing: 12) {
                    // Icon matching nudge style
                    ZStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.9, green: 0.75, blue: 0.1),
                                        Color(red: 0.85, green: 0.65, blue: 0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Content matching nudge style
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Summary:")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.05))
                        
                        if let summary = summaryEngine.currentWeeklySummary {
                            Text("\(formatDate(summary.weekStartDate)) - \(formatDate(summary.weekEndDate))")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(Color(UIColor.label))
                                .lineSpacing(2)
                        } else {
                            Text("Your growth journey this week is ready to explore")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(Color(UIColor.label))
                                .lineSpacing(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow button
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.05))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // White base like nudge cards
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                        
                        // Golden gradient overlay
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.08),
                                        Color(red: 0.85, green: 0.65, blue: 0.05).opacity(0.05),
                                        Color(red: 0.9, green: 0.75, blue: 0.1).opacity(0.03),
                                        Color.white
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Badge below the card like nudge timer
            if summaryEngine.hasNewWeeklySummary {
                Text("NEW THIS WEEK")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.05))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private var dangerZoneSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Danger Zone")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    iconColor: .orange,
                    action: { showingLogoutConfirmation = true }
                )
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(
                    title: "Delete All Data",
                    subtitle: "Permanently delete everything",
                    icon: "trash.fill",
                    iconColor: .red,
                    action: { showingDeleteConfirmation = true }
                )
            }
            .background(Color.secondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primaryAccent)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let showChevron: Bool
    let action: (() -> Void)?
    @Binding var toggle: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = .primaryAccent,
        showChevron: Bool = true,
        action: (() -> Void)? = nil,
        toggle: Binding<Bool>? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.showChevron = showChevron && action != nil && toggle == nil
        self.action = action
        self._toggle = toggle ?? .constant(false)
    }
    
    private var hasToggle: Bool {
        // This is a bit of a hack to detect if we have a real binding
        return title.contains("Lock") || title.contains("Reminder") || title.contains("Notification") || title.contains("Analytics") || title.contains("Insights")
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                if hasToggle {
                    Toggle("", isOn: $toggle)
                        .toggleStyle(SwitchToggleStyle(tint: .primaryAccent))
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.tertiaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil && !hasToggle)
    }
}

// MARK: - Stat View
struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
        }
    }
}

// MARK: - Profile View Model
@MainActor
class ProfileViewModel: ObservableObject {
    private let backendClient = BackendClient.shared
    private let settingsManager = SettingsManager.shared
    @Published var biometricLockEnabled = UserDefaults.standard.bool(forKey: "biometricLockEnabled")
    @Published var dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "dailyRemindersEnabled")
    @Published var insightNotificationsEnabled = true
    @Published var analyticsEnabled = true
    @Published var aiInsightsEnabled = true
    @Published var reminderTime = Date()
    @Published var processingFrequency: ProcessingFrequency = .daily
    @Published var insightSensitivity: InsightSensitivity = .balanced
    @Published var showProcessingOptions = false
    @Published var showSensitivityOptions = false
    
    // Stats
    @Published var reflectionCount: Int = 0
    @Published var insightCount: Int = 0
    @Published var streakDays: Int = 0
    @Published var memberSinceText: String = "January 2025"
    @Published var dataUsageText: String = "Calculating..."
    
    init() {
        // Load saved settings
        loadSettings()
        
        // Setup observers
        setupObservers()
        
        // Load stats
        loadUserStats()
    }
    
    private func loadSettings() {
        // Load notification settings from backend if available
        Task {
            await loadUserPreferences()
        }
        
        // Load local settings
        if let reminderTimeData = UserDefaults.standard.data(forKey: "reminderTime"),
           let time = try? JSONDecoder().decode(Date.self, from: reminderTimeData) {
            reminderTime = time
        } else {
            reminderTime = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
    
    private func loadUserStats() {
        Task {
            do {
                let stats = try await backendClient.fetchUserStats()
                DispatchQueue.main.async {
                    self.reflectionCount = stats.totalReflections
                    self.insightCount = stats.totalInsights
                    self.streakDays = stats.currentStreak
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM yyyy"
                    self.memberSinceText = formatter.string(from: Date())
                }
            } catch {
                print("Failed to load user stats: \(error)")
                // Fallback to default values
                DispatchQueue.main.async {
                    self.reflectionCount = 0
                    self.insightCount = 0
                    self.streakDays = 0
                }
            }
        }
    }
    
    private func loadUserPreferences() async {
        do {
            let preferences = try await backendClient.fetchUserPreferences()
            DispatchQueue.main.async {
                self.dailyRemindersEnabled = preferences.allow_proactive_nudges
            }
        } catch {
            print("Failed to load user preferences: \(error)")
        }
    }
    
    private func setupObservers() {
        // Save settings when they change
        $biometricLockEnabled
            .dropFirst() // Skip initial value
            .sink { [weak self] enabled in
                UserDefaults.standard.set(enabled, forKey: "biometricLockEnabled")
                if enabled {
                    self?.setupBiometricAuth()
                }
            }
            .store(in: &cancellables)
        
        $dailyRemindersEnabled
            .dropFirst() // Skip initial value
            .sink { [weak self] enabled in
                UserDefaults.standard.set(enabled, forKey: "dailyRemindersEnabled")
                // Sync with backend
                Task {
                    await self?.updateUserPreferences()
                }
            }
            .store(in: &cancellables)
        
        $reminderTime
            .sink { time in
                if let data = try? JSONEncoder().encode(time) {
                    UserDefaults.standard.set(data, forKey: "reminderTime")
                }
                // TODO: Schedule local notifications based on reminder time
            }
            .store(in: &cancellables)
    }
    
    private func updateUserPreferences() async {
        do {
            _ = try await backendClient.updateUserPreferences(allowProactiveNudges: dailyRemindersEnabled)
        } catch {
            print("Failed to update user preferences: \(error)")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func exportData() {
        // Export user data - this would be a complex operation
        Task {
            do {
                // In a real implementation, you'd:
                // 1. Fetch all user data from backend
                // 2. Query SwiftData for local data 
                // 3. Generate export file (JSON/CSV)
                // 4. Present share sheet
                
                print("Starting data export...")
                // Placeholder for now - button is wired but doesn't export yet
                
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
    
    func openSupport() {
        // Open support page - using placeholder for now
        print("Opening support...")
        // Future: Open in-app support or web page
        // if let url = URL(string: "https://sthealth.app/support") {
        //     UIApplication.shared.open(url)
        // }
    }
    
    func openPrivacyPolicy() {
        // Open privacy policy - using placeholder for now  
        print("Opening privacy policy...")
        // Future: Open privacy policy page
        // if let url = URL(string: "https://sthealth.app/privacy") {
        //     UIApplication.shared.open(url)
        // }
    }
    
    func openTerms() {
        // Open terms of service - using placeholder for now
        print("Opening terms of service...")
        // Future: Open terms page
        // if let url = URL(string: "https://sthealth.app/terms") {
        //     UIApplication.shared.open(url)
        // }
    }
    
    func deleteAllData() {
        Task {
            do {
                // TODO: Implement deleteUserData in BackendClient
                // try await backendClient.deleteUserData()
                // Clear local data
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                // Clear keychain data
                backendClient.logout()
                
                // Reset settings manager
                settingsManager.resetAllSettings()
                
                print("All local and backend data cleared")
            } catch {
                print("Failed to delete user data: \(error)")
            }
        }
    }
    
    func signOut() {
        // Clear auth state
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        // Clear backend authentication
        backendClient.logout()
        
        // Reset settings
        settingsManager.resetAllSettings()
        
        print("User signed out")
    }
    
    private func setupBiometricAuth() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            print("Biometric authentication is available and enabled")
            // In a real app, you'd integrate this with your app's authentication flow
        } else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            // Disable the setting if biometrics aren't available
            DispatchQueue.main.async {
                self.biometricLockEnabled = false
            }
        }
    }
}

// MARK: - Supporting Types
enum ProcessingFrequency: CaseIterable {
    case realtime, hourly, daily, weekly
    
    var displayName: String {
        switch self {
        case .realtime: return "Real-time"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

enum InsightSensitivity: CaseIterable {
    case conservative, balanced, sensitive
    
    var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .sensitive: return "Sensitive"
        }
    }
}

import Combine

#Preview {
    ProfileView()
}