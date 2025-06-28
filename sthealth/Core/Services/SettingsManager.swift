//
//  SettingsManager.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/22/25.
//

import Foundation
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func resetAllSettings() {
        userName = ""
        hasCompletedOnboarding = false
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "userName")
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.synchronize()
    }
}