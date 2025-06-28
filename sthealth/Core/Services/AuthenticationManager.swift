//
//  AuthenticationManager.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/24/25.
//

import Foundation
import SwiftUI

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userName: String = ""
    
    private let backendClient = BackendClient.shared
    
    init() {
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        isAuthenticated = backendClient.isAuthenticated
    }
    
    func register(name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await backendClient.register(userName: name)
            print("Registration successful for user: \(response.user_id)")
            userName = name
            isAuthenticated = true
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
            print("Registration error: \(error)")
        }
        
        isLoading = false
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await backendClient.login()
            print("Login successful for user: \(response.user_id)")
            isAuthenticated = true
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
            print("Login error: \(error)")
        }
        
        isLoading = false
    }
    
    func logout() {
        backendClient.logout()
        isAuthenticated = false
        userName = ""
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}