//
//  APIDataModels.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/24/25.
//

import Foundation

// MARK: - Request Models

struct DataPointCreate: Codable {
    let data_type: String
    let source: String
    let payload: [String: AnyCodable]
    
    init(data_type: String, source: String, payload: [String: Any]) {
        self.data_type = data_type
        self.source = source
        self.payload = payload.mapValues { AnyCodable($0) }
    }
}

struct RegisterRequest: Codable {
    let device_uuid: String
    let name: String
}

struct LoginRequest: Codable {
    let device_uuid: String
}

// MARK: - Response Models

struct RegisterResponse: Codable {
    let token: String
    let user_id: String
    let device_id: String
}

struct LoginResponse: Codable {
    let token: String
    let user_id: String
}

struct DataPointResponse: Codable {
    let id: String
    let data_type: String
    let source: String
    let payload: [String: AnyCodable]
    let timestamp: String
    let user_id: String
}

struct Insight: Codable {
    let id: String
    let content: String
    let insight_type: String
    let created_at: String
    let user_id: String
    let metadata: [String: AnyCodable]?
}

struct InsightsResponse: Codable {
    let insights: [Insight]
}



// MARK: - Workshop Models

struct WorkshopSessionRequest: Codable {
    let hypothesis_id: String
}

struct WorkshopSessionResponse: Codable {
    let session_id: String
    let hypothesis_id: String
    let created_at: String
    let status: String
}

struct WorkshopMessage: Codable {
    let id: String
    let session_id: String
    let content: String
    let role: String
    let timestamp: String
    let metadata: [String: AnyCodable]?
}

struct WorkshopMessageRequest: Codable {
    let text: String
}

struct WorkshopCommitResponse: Codable {
    let insight_id: String
    let content: String
    let created_at: String
}

// MARK: - Atlas Models



struct ThreadTimelineItem: Codable {
    let id: String
    let type: String
    let content: String
    let timestamp: String
    let metadata: [String: AnyCodable]?
}

struct ThreadTimeline: Codable {
    let thread_id: String
    let items: [ThreadTimelineItem]
}

// MARK: - User Preferences Models

struct UserPreferences: Codable {
    let allow_proactive_nudges: Bool
    let notification_frequency: String?
    let updated_at: String
}

struct UserPreferencesRequest: Codable {
    let allow_proactive_nudges: Bool
}

struct PushTokenRequest: Codable {
    let device_token: String
    let platform: String
}

// MARK: - Response Models

struct EmptyResponse: Codable {}

// MARK: - Error Models

struct APIError: Codable, Error {
    let detail: String
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}