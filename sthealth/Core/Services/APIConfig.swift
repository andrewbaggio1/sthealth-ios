//
//  APIConfig.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/24/25.
//

import Foundation

struct APIConfig {
    static let baseURL = "https://sthealth-backend-632783708061.us-central1.run.app"
    
    struct Endpoints {
        static let register = "/register"
        static let login = "/login/device"
        static let dataPoints = "/data-points/"
        static let insights = "/insights/"
        static let hypotheses = "/hypotheses/pending"
        static let workshopSessions = "/workshop/sessions"
        static let atlasThreads = "/atlas/threads"
        static let userPreferences = "/user/preferences"
        static let pushToken = "/users/push-token"
        
        static func workshopMessages(sessionId: String) -> String {
            return "/workshop/sessions/\(sessionId)/messages"
        }
        
        static func workshopCommit(sessionId: String) -> String {
            return "/workshop/sessions/\(sessionId)/commit"
        }
        
        static func threadTimeline(threadId: String) -> String {
            return "/atlas/threads/\(threadId)/timeline"
        }
        static let moments = "/moments"
    }
    
    struct Keys {
        static let deviceUUID = "sthealth_device_uuid"
        static let jwtToken = "sthealth_jwt_token"
    }
}