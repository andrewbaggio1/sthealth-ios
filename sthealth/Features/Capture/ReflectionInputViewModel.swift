import SwiftUI
import AVFoundation
import Speech
import PhotosUI
import Combine

@MainActor
class ReflectionInputViewModel: ObservableObject {
    // Published properties
    @Published var reflectionText = ""
    @Published var isRecording = false
    @Published var isSubmitting = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingPulse = false
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedImageData: Data?
    @Published var errorMessage: String?
    
    // Track input method for proper detection
    @Published var lastInputMethod: InputMethod = .text
    
    // Audio session
    private var audioSession = AVAudioSession.sharedInstance()
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Backend client
    private let backendClient = BackendClient.shared
    private let engagementTracker = EngagementTracker.shared
    
    // Track reflection timing
    private var reflectionStartTime: Date?
    private var wordCount: Int {
        reflectionText.split(separator: " ").count
    }
    
    // Input method enum
    enum InputMethod {
        case text
        case voice
        case image
        case combined
    }
    
    // Computed properties
    var canSubmit: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
        selectedImageData != nil
    }
    
    init() {
        observePhotoSelection()
        observeTextChanges()
        setupReflectionTracking()
    }
    
    // MARK: - Setup
    
    
    private func observePhotoSelection() {
        $selectedPhoto
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.loadSelectedPhoto(item)
                }
            }
            .store(in: &cancellables)
    }
    
    private func observeTextChanges() {
        $reflectionText
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                // Only update input method if user is manually typing (not during speech recognition)
                if !self.isRecording && !text.isEmpty && self.lastInputMethod == .text {
                    self.lastInputMethod = .text
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupReflectionTracking() {
        // Start timing when user begins typing
        $reflectionText
            .sink { [weak self] text in
                if text.count == 1 && self?.reflectionStartTime == nil {
                    // First character typed - start timing
                    self?.reflectionStartTime = Date()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Permissions
    func requestPermissions() {
        audioSession.requestRecordPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.errorMessage = "Microphone permission is required for voice recordings"
                }
            }
        }
        
        SFSpeechRecognizer.requestAuthorization { status in
            if status != .authorized {
                DispatchQueue.main.async {
                    self.errorMessage = "Speech recognition permission is required for voice-to-text"
                }
            }
        }
    }
    
    // MARK: - Recording
    func startRecording() {
        guard !isRecording else { return }
        
        clearError()
        
        // Check permissions
        guard audioSession.recordPermission == .granted else {
            errorMessage = "Microphone permission required"
            return
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition permission required"
            return
        }
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            // Start speech recognition
            startSpeechRecognition()
            
            // Update UI and track input method
            isRecording = true
            recordingStartTime = Date()
            recordingPulse = true
            lastInputMethod = .voice
            
            // Start timer
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    self.updateRecordingDuration()
                }
            }
            
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop speech recognition
        stopSpeechRecognition()
        
        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Update UI
        isRecording = false
        recordingPulse = false
        recordingDuration = 0
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        recordingDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Speech Recognition
    private func startSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start speech recognition: \(error.localizedDescription)"
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.reflectionText = result.bestTranscription.formattedString
                    // Ensure input method remains as voice during recognition
                    if self.isRecording {
                        self.lastInputMethod = .voice
                    }
                }
            }
            
            if let error = error {
                // Only show error if we're still recording (genuine error)
                // Don't show errors when we intentionally stop recording
                if self.isRecording {
                    DispatchQueue.main.async {
                        self.errorMessage = "Speech recognition error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func stopSpeechRecognition() {
        // Add a small delay to allow the speech recognizer to process the final buffer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.audioEngine.stop()
            self.audioEngine.inputNode.removeTap(onBus: 0)
            self.recognitionRequest?.endAudio()
            self.recognitionRequest = nil
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
        }
    }
    
    // MARK: - Image Handling
    private func loadSelectedPhoto(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                // Update input method based on content
                if !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lastInputMethod = .combined
                } else {
                    lastInputMethod = .image
                }
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }
    
    func removeSelectedImage() {
        selectedPhoto = nil
        selectedImageData = nil
        // Update input method after removing image
        if !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastInputMethod = lastInputMethod == .voice ? .voice : .text
        } else {
            lastInputMethod = .text
        }
    }
    
    // MARK: - Submission
    func submitReflection() {
        guard canSubmit && !isSubmitting else { return }
        
        isSubmitting = true
        clearError()
        
        // Calculate reflection duration
        let reflectionDuration = reflectionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        Task {
            do {
                // Create data point for backend
                var payload: [String: Any] = [:]
                
                // Add text if available
                let trimmedText = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedText.isEmpty {
                    payload["text"] = trimmedText
                }
                
                // Add image if available
                if let imageData = selectedImageData {
                    payload["image"] = imageData.base64EncodedString()
                    payload["image_format"] = "base64"
                }
                
                // Add metadata
                payload["timestamp"] = ISO8601DateFormatter().string(from: Date())
                payload["input_method"] = determineInputMethod()
                payload["word_count"] = wordCount
                payload["reflection_duration"] = reflectionDuration
                
                let dataPoint = DataPointCreate(
                    data_type: "reflection",
                    source: "app_capture",
                    payload: payload
                )
                
                // Submit to backend
                let response = try await backendClient.submitDataPoints([dataPoint])
                
                // Track engagement for reflection completion
                engagementTracker.trackReflectionEntry(
                    reflectionId: response.first?.id ?? UUID().uuidString,
                    wordCount: wordCount,
                    duration: reflectionDuration,
                    inputMethod: determineInputMethod()
                )
                
                // Success - clear form
                await MainActor.run {
                    clearForm()
                    // Could show success message here
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit reflection: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
    
    private func determineInputMethod() -> String {
        switch lastInputMethod {
        case .text:
            return selectedImageData != nil ? "text_and_image" : "text_only"
        case .voice:
            return selectedImageData != nil ? "voice_and_image" : "voice_to_text"
        case .image:
            return "image_only"
        case .combined:
            return "text_and_image"
        }
    }
    
    private func clearForm() {
        reflectionText = ""
        selectedPhoto = nil
        selectedImageData = nil
        isSubmitting = false
        lastInputMethod = .text
        
        // Stop recording if active
        if isRecording {
            stopRecording()
        }
    }
    
    private func clearError() {
        errorMessage = nil
    }
}

