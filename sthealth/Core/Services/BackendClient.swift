//
//  BackendClient.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/24/25.
//

import Foundation
import Security

final class BackendClient {
    static let shared = BackendClient()
    
    private let session = URLSession.shared
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private init() {}
    
    // MARK: - Keychain Management
    
    private func saveToKeychain(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    private func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Device ID and JWT Management
    
    private func getOrCreateDeviceUUID() -> String {
        if let data = loadFromKeychain(key: APIConfig.Keys.deviceUUID),
           let uuid = String(data: data, encoding: .utf8) {
            return uuid
        }
        
        let newUUID = UUID().uuidString
        if let data = newUUID.data(using: .utf8) {
            _ = saveToKeychain(key: APIConfig.Keys.deviceUUID, data: data)
        }
        return newUUID
    }
    
    private func saveJWTToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return saveToKeychain(key: APIConfig.Keys.jwtToken, data: data)
    }
    
    private func getJWTToken() -> String? {
        guard let data = loadFromKeychain(key: APIConfig.Keys.jwtToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func clearJWTToken() -> Bool {
        return deleteFromKeychain(key: APIConfig.Keys.jwtToken)
    }
    
    // MARK: - Authentication
    
    func register(userName: String) async throws -> RegisterResponse {
        let deviceUUID = getOrCreateDeviceUUID()
        let request = RegisterRequest(device_uuid: deviceUUID, name: userName)
        
        let response: RegisterResponse = try await makeRequest(
            endpoint: APIConfig.Endpoints.register,
            method: "POST",
            body: request,
            requiresAuth: false
        )
        
        _ = saveJWTToken(response.token)
        return response
    }
    
    func login() async throws -> LoginResponse {
        let deviceUUID = getOrCreateDeviceUUID()
        let request = LoginRequest(device_uuid: deviceUUID)
        
        let response: LoginResponse = try await makeRequest(
            endpoint: APIConfig.Endpoints.login,
            method: "POST",
            body: request,
            requiresAuth: false
        )
        
        _ = saveJWTToken(response.token)
        return response
    }
    
    func logout() {
        _ = clearJWTToken()
    }
    
    var isAuthenticated: Bool {
        return getJWTToken() != nil
    }
    
    // MARK: - Data Operations
    
    func submitDataPoints(_ dataPoints: [DataPointCreate]) async throws -> [DataPointResponse] {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.dataPoints,
            method: "POST",
            body: dataPoints,
            requiresAuth: true
        )
    }
    
    func fetchNewInsights() async throws -> InsightsResponse {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.insights,
            method: "GET",
            requiresAuth: true
        )
    }
    
    func fetchPendingHypotheses() async throws -> [Hypothesis] {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.hypotheses,
            method: "GET",
            requiresAuth: true
        )
    }
    
    // MARK: - Workshop Methods
    
    func createWorkshopSession(hypothesisId: String) async throws -> WorkshopSessionResponse {
        let request = WorkshopSessionRequest(hypothesis_id: hypothesisId)
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.workshopSessions,
            method: "POST",
            body: request,
            requiresAuth: true
        )
    }
    
    func sendWorkshopMessage(sessionId: String, text: String) async throws -> WorkshopMessage {
        let request = WorkshopMessageRequest(text: text)
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.workshopMessages(sessionId: sessionId),
            method: "POST",
            body: request,
            requiresAuth: true
        )
    }
    
    func commitWorkshopSession(sessionId: String) async throws -> WorkshopCommitResponse {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.workshopCommit(sessionId: sessionId),
            method: "POST",
            requiresAuth: true
        )
    }
    
    // MARK: - Atlas Methods
    
    func fetchNarrativeThreads() async throws -> [NarrativeThread] {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.atlasThreads,
            method: "GET",
            requiresAuth: true
        )
    }
    
    func fetchThreadTimeline(threadId: String) async throws -> ThreadTimeline {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.threadTimeline(threadId: threadId),
            method: "GET",
            requiresAuth: true
        )
    }
    
    // MARK: - User Preferences Methods
    
    func fetchUserPreferences() async throws -> UserPreferences {
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.userPreferences,
            method: "GET",
            requiresAuth: true
        )
    }
    
    func updateUserPreferences(allowProactiveNudges: Bool) async throws -> UserPreferences {
        let request = UserPreferencesRequest(allow_proactive_nudges: allowProactiveNudges)
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.userPreferences,
            method: "POST",
            body: request,
            requiresAuth: true
        )
    }
    
    func submitPushToken(deviceToken: String) async throws {
        let request = PushTokenRequest(device_token: deviceToken, platform: "ios")
        let _: EmptyResponse = try await makeRequest(
            endpoint: APIConfig.Endpoints.pushToken,
            method: "POST",
            body: request,
            requiresAuth: true
        )
    }
    
    func saveMoment(moment: Moment) async throws -> MomentResponse {
        let request = MomentCreateRequest(
            content: moment.text,
            modality: moment.modality.rawValue,
            image_data: nil // Image data handled separately through data points
        )
        return try await makeRequest(
            endpoint: APIConfig.Endpoints.moments,
            method: "POST",
            body: request,
            requiresAuth: true
        )
    }
    
    // MARK: - Private Network Methods
    
    private func makeRequest<T: Codable, B: Codable>(
        endpoint: String,
        method: String,
        body: B? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        print("--> Making request to: \(APIConfig.baseURL)\(endpoint)")
        
        let url = URL(string: APIConfig.baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            guard let token = getJWTToken() else {
                throw BackendError.notAuthenticated
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try jsonEncoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try jsonDecoder.decode(T.self, from: data)
        case 401:
            _ = clearJWTToken()
            throw BackendError.unauthorized
        case 400...499:
            if let apiError = try? jsonDecoder.decode(APIError.self, from: data) {
                throw BackendError.clientError(apiError.detail)
            }
            throw BackendError.clientError("Client error: \(httpResponse.statusCode)")
        case 500...599:
            throw BackendError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw BackendError.unknown("Unexpected status code: \(httpResponse.statusCode)")
        }
    }
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: method, body: EmptyBody?.none, requiresAuth: requiresAuth)
    }
}

// MARK: - Request/Response Models for Moment
struct MomentCreateRequest: Codable {
    let content: String
    let modality: String
    let image_data: String? // Base64 encoded string
}

struct MomentResponse: Codable, Identifiable {
    let id: Int
    let content: String
    let modality: String
    let image_data: String?
    let user_id: Int
    let created_at: Date
}

// MARK: - Error Types

enum BackendError: Error, LocalizedError {
    case notAuthenticated
    case unauthorized
    case invalidResponse
    case clientError(String)
    case serverError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .invalidResponse:
            return "Invalid response from server."
        case .clientError(let message):
            return "Client error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Helper Types

private struct EmptyBody: Codable {}