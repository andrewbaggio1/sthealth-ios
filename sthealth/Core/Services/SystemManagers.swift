//
//  SystemManagers.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/01/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import UserNotifications
import EventKit
import Speech
import AVFoundation

// MARK: - ContextManager
final class ContextManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentContextVector: [String: Double] = [:]
    @Published var lastKnownLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    private let eventStore = EKEventStore()

    override init() {
        super.init()
        self.locationManager.delegate = self
    }
    
    func requestPermissionsAndStartMonitoring() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        Task { await updateContext(from: self.lastKnownLocation) }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lastKnownLocation = location
            Task { await updateContext(from: location) }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
    }

    // FIXED: Rewritten to be fully concurrency-safe and prevent data races.
    func updateContext(from location: CLLocation?) async {
        let now = Date()
        let calendar = Calendar.current
        
        var vector: [String: Double] = [
            "hour_of_day": Double(calendar.component(.hour, from: now)) / 24.0,
            "is_weekday": (calendar.component(.weekday, from: now) > 1 && calendar.component(.weekday, from: now) < 7) ? 1.0 : 0.0
        ]

        if location != nil {
            let isWorkday = vector["is_weekday"] == 1.0
            let hour = calendar.component(.hour, from: now)
            let isWorkHours = isWorkday && hour >= 9 && hour <= 17
            vector["at_work"] = isWorkHours ? 1.0 : 0.0
            vector["at_home"] = isWorkHours ? 0.0 : 1.0
        }
        
        let hasCalendarAccess = await requestCalendarAccess()
        if hasCalendarAccess {
            // Create a copy of vector for async modification
            var updatedVector = vector
            let oneHourFromNow = now.addingTimeInterval(3600)
            let predicate = eventStore.predicateForEvents(withStart: now, end: oneHourFromNow, calendars: nil)
            let events = eventStore.events(matching: predicate)
            
            updatedVector["has_upcoming_event"] = events.isEmpty ? 0.0 : 1.0
            updatedVector["has_work_meeting"] = events.contains { $0.title.lowercased().contains("meeting") } ? 1.0 : 0.0
            vector = updatedVector
        }
        
        await MainActor.run { self.currentContextVector = vector }
    }

    private func requestCalendarAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let status = EKEventStore.authorizationStatus(for: .event)
                if status == .notDetermined { return try await eventStore.requestFullAccessToEvents() }
                return status == .fullAccess
            } else {
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in continuation.resume(returning: granted) }
                }
            }
        } catch { print("Calendar access error: \(error)"); return false }
    }
}

// MARK: - NotificationManager
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    override private init() { super.init(); UNUserNotificationCenter.current().delegate = self }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleNotification(id: UUID, text: String) async {
        let content = UNMutableNotificationContent()
        content.body = text
        content.sound = .default
        content.userInfo = ["notificationId": id.uuidString]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
}

// MARK: - PredictiveEngine
@MainActor
final class PredictiveEngine: ObservableObject {
    private let cognitiveEngine = CognitiveEngine.shared
    private var timer: Timer?
    private var modelContext: ModelContext?
    private weak var contextManager: ContextManager?

    func beginMonitoring(modelContext: ModelContext, contextManager: ContextManager) {
        self.modelContext = modelContext
        self.contextManager = contextManager
        
        Task { await contextManager.updateContext(from: contextManager.lastKnownLocation) }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { await self?.runPeriodicCheck() }
        }
    }
    
    private func runPeriodicCheck() async {
        guard let contextManager, let modelContext else { return }
        await contextManager.updateContext(from: contextManager.lastKnownLocation)
        await checkAndGenerateNotifications(contextManager: contextManager, modelContext: modelContext)
    }

    private func checkAndGenerateNotifications(contextManager: ContextManager, modelContext: ModelContext) async {
        let contextDescription = describeContext(contextManager.currentContextVector)
        let prediction = "procrastination" // Placeholder
        guard shouldTriggerNotification(for: prediction) else { return }
              
        if let notificationText = await cognitiveEngine.generateNotificationText(context: contextDescription, predictedState: prediction) {
            let newNotification = Notification(text: notificationText, triggerContext: encodeContext(contextManager.currentContextVector), predictedState: prediction)
            modelContext.insert(newNotification)
            try? modelContext.save()
            
            newNotification.interaction = NotificationInteractionType.shown
            await NotificationManager.shared.scheduleNotification(id: newNotification.id, text: newNotification.text)
        }
    }
    
    private func shouldTriggerNotification(for state: String) -> Bool {
        ["anxiety", "stress", "procrastination", "self-doubt"].contains { state.lowercased().contains($0) }
    }
    private func describeContext(_ vector: [String: Double]) -> String {
        var parts: [String] = []
        if vector["at_work"] == 1.0 { parts.append("at work") }
        if vector["has_work_meeting"] == 1.0 { parts.append("before a meeting") }
        return parts.isEmpty ? "in their day" : parts.joined(separator: ", ")
    }
    private func encodeContext(_ vector: [String: Double]) -> String {
        (try? JSONEncoder().encode(vector).base64EncodedString()) ?? "{}"
    }
}

// MARK: - SpeechRecognizer
final class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isListening = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() { super.init(); self.speechRecognizer.delegate = self }

    // FIXED: This now correctly uses the modern static method on AVAudioApplication
    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func startTranscribing(onUpdate: @escaping (String) -> Void) throws {
        recognitionTask?.cancel(); self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { fatalError("Unable to create request") }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result { onUpdate(result.bestTranscription.formattedString) }
            if error != nil || result?.isFinal == true { self.stopTranscribing() }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare(); try audioEngine.start()
        DispatchQueue.main.async { self.isListening = true }
    }

    func stopTranscribing() {
        if audioEngine.isRunning {
            audioEngine.stop(); audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        DispatchQueue.main.async { self.isListening = false }
    }
}
