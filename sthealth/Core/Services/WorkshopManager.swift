
import Foundation
import Combine

class WorkshopManager: ObservableObject {
    static let shared = WorkshopManager()
    private init() {}

    @Published var messages: [SessionMessage] = []
    @Published var isSessionActive = false
    @Published var showWorkshopView = false
    @Published var isLoading = false
    @Published var lastError: String?

    private var session: WorkshopSession?
    private var cancellables = Set<AnyCancellable>()

    func startSession(hypothesisId: Int) {
        // In a real app, you would make a network request to create the session
        self.session = WorkshopSession(id: 1, userId: 1, status: "active", messages: [])
        self.isSessionActive = true
        self.messages = []
    }

    func sendMessage(_ content: String) {
        guard let session = session else { return }

        let userMessage = SessionMessage(id: Int.random(in: 100...1000), sessionId: session.id, senderType: "user", content: content)
        messages.append(userMessage)

        // In a real app, you would send the message to the backend
        // and receive an AI response.
        let aiResponse = SessionMessage(id: Int.random(in: 100...1000), sessionId: session.id, senderType: "ai", content: "That's interesting. Tell me more.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.messages.append(aiResponse)
        }
    }

    func commitInsight() {
        guard let session = session else { return }
        // In a real app, you would make a network request to commit the insight
        print("Committing insight for session \(session.id)")
        endSession()
    }

    func commitSession() async -> Bool {
        guard let session = session else { return false }
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(for: .seconds(1))
        
        isLoading = false
        endSession()
        return true
    }
    
    func endSession() {
        self.session = nil
        self.isSessionActive = false
    }
}

// Dummy data structures for preview
struct WorkshopSession: Identifiable {
    let id: Int
    let userId: Int
    let status: String
    var messages: [SessionMessage]
}

struct SessionMessage: Identifiable {
    let id: Int
    let sessionId: Int
    let senderType: String
    let content: String
}
