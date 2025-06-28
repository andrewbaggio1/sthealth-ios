//
//  OnboardingView.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/22/25.
//

import SwiftUI
import CoreLocation
import EventKit
import AVFoundation
import Speech
import LocalAuthentication

enum OnboardingState {
    case splash
    case nameInput
    case locationPermission
    case calendarPermission
    case microphonePermission
    case authentication
    case completed
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentState: OnboardingState = .splash
    @State private var userName: String = ""
    @StateObject private var authManager = AuthenticationManager()
    
    private let locationManager = CLLocationManager()
    private let eventStore = EKEventStore()
    
    var body: some View {
        ZStack {
            // Apple Glass Background
            LinearGradient(
                colors: [
                    Color.primaryBackground,
                    Color.secondaryBackground,
                    Color.primaryBackground.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            switch currentState {
            case .splash:
                SplashView()
                    .onAppear {
                        checkExistingAuth()
                    }
                    
            case .nameInput:
                NameInputView(userName: $userName, authManager: authManager) {
                    registerUser()
                }
                
            case .locationPermission:
                PermissionView(
                    title: "Location Access",
                    description: "We use your location to provide contextual insights about your cognitive patterns and environments.",
                    icon: "location.fill"
                ) {
                    requestLocationPermission()
                }
                
            case .calendarPermission:
                PermissionView(
                    title: "Calendar Access",
                    description: "Access your calendar to understand how events and schedules affect your mental state.",
                    icon: "calendar"
                ) {
                    requestCalendarPermission()
                }
                
            case .microphonePermission:
                PermissionView(
                    title: "Microphone & Speech",
                    description: "Record voice memos and convert speech to text for richer cognitive analysis.",
                    icon: "mic.fill"
                ) {
                    requestMicrophonePermission()
                }
                
            case .authentication:
                AuthenticationView(
                    onAuthenticate: requestBiometricAuthentication,
                    completeOnboarding: completeOnboarding
                )
            
            case .completed:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentState)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && currentState == .nameInput {
                // Skip onboarding for returning users
                completeOnboarding()
            }
        }
    }
    
    private func checkExistingAuth() {
        // Check if user is already authenticated
        if authManager.isAuthenticated {
            // User is already logged in, skip onboarding
            completeOnboarding()
        } else {
            // New user or logged out, proceed with onboarding
            startSplashTimer()
        }
    }
    
    private func startSplashTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            transitionTo(.nameInput)
        }
    }
    
    private func transitionTo(_ newState: OnboardingState) {
        withAnimation {
            currentState = newState
        }
    }
    
    private func registerUser() {
        Task {
            await authManager.register(name: userName)
            if authManager.isAuthenticated {
                UserDefaults.standard.set(userName, forKey: "userName")
                transitionTo(.locationPermission)
            }
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        transitionTo(.calendarPermission)
    }
    
    private func requestCalendarPermission() {
        eventStore.requestFullAccessToEvents { _, _ in
            DispatchQueue.main.async {
                transitionTo(.microphonePermission)
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            SFSpeechRecognizer.requestAuthorization { _ in
                DispatchQueue.main.async {
                    transitionTo(.authentication)
                }
            }
        }
    }
    
    private func requestBiometricAuthentication() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Secure your cognitive insights with biometric authentication"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        completeOnboarding()
                    } else {
                        requestPasscodeAuthentication()
                    }
                }
            }
        } else {
            requestPasscodeAuthentication()
        }
    }
    
    private func requestPasscodeAuthentication() {
        let context = LAContext()
        let reason = "Secure your cognitive insights with your device passcode"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { _, _ in
            DispatchQueue.main.async {
                self.completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
        // Ensure we properly dismiss the onboarding
        DispatchQueue.main.async {
            self.hasCompletedOnboarding = true
        }
    }
}

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    // Glass background for logo
                    Circle()
                        .fill(GlassMaterial.primary)
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.glassBorder, lineWidth: 0.5)
                        )
                        .shadow(
                            color: .glassShadow.opacity(0.2),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60, weight: .ultraLight))
                        .foregroundColor(.primaryAccent)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                Text("sthealth")
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.primaryText)
                    .tracking(1.2)
                .opacity(logoOpacity)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(AppAnimation.fluid.delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

struct NameInputView: View {
    @Binding var userName: String
    @ObservedObject var authManager: AuthenticationManager
    let onSubmit: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @State private var isCheckingUser = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                VStack(spacing: 24) {
                    // Glass logo
                    ZStack {
                        Circle()
                            .fill(GlassMaterial.primary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color.glassBorder, lineWidth: 0.5)
                            )
                            .shadow(
                                color: .glassShadow.opacity(0.2),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 44, weight: .ultraLight))
                            .foregroundColor(.primaryAccent)
                    }
                    
                    Text("sthealth")
                        .font(.system(size: 32, weight: .thin, design: .rounded))
                        .foregroundColor(.primaryText)
                        .tracking(1.2)
                }
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("What should we call you?")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primaryText)
                        
                        TextField("First Name", text: $userName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.9))
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(GlassMaterial.primary)
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [.glassHighlight.opacity(0.3), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.glassBorder, lineWidth: 0.5)
                            )
                            .shadow(
                                color: .glassShadow.opacity(0.15),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    onSubmit()
                                }
                            }
                    }
                    .padding(.horizontal, 60)
                    
                    Button("Continue") {
                        onSubmit()
                    }
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authManager.isLoading || isCheckingUser)
                    .buttonStyle(GlassButtonStyle())
                    .padding(.horizontal, 60)
                    
                    if authManager.isLoading || isCheckingUser {
                        ProgressView(isCheckingUser ? "Checking..." : "Registering...")
                            .padding(.top, 16)
                    }
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                            .onTapGesture {
                                authManager.clearError()
                            }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
            // Check if there's a stored username
            if let storedName = UserDefaults.standard.string(forKey: "userName") {
                userName = storedName
                isCheckingUser = true
                // Try to login with existing credentials
                Task {
                    await authManager.login()
                    isCheckingUser = false
                }
            }
        }
    }
}

struct PermissionView: View {
    let title: String
    let description: String
    let icon: String
    let onAllow: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 48) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(GlassMaterial.primary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color.glassBorder, lineWidth: 0.5)
                            )
                            .shadow(
                                color: .glassShadow.opacity(0.2),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 44, weight: .ultraLight))
                            .foregroundColor(.primaryAccent)
                    }
                    
                    VStack(spacing: 16) {
                        Text(title)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 32)
                    }
                }
                
                VStack(spacing: 16) {
                    Button("Continue") {
                        onAllow()
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button("Not Now") {
                        onAllow()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct AuthenticationView: View {
    let onAuthenticate: () -> Void
    let completeOnboarding: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 48) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(GlassMaterial.primary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color.glassBorder, lineWidth: 0.5)
                            )
                            .shadow(
                                color: .glassShadow.opacity(0.2),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        
                        Image(systemName: "faceid")
                            .font(.system(size: 44, weight: .ultraLight))
                            .foregroundColor(.primaryAccent)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Secure Your Data")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Your cognitive insights are deeply personal. Let's secure them with biometric authentication.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 32)
                    }
                }
                
                VStack(spacing: 16) {
                    Button("Enable Security") {
                        onAuthenticate()
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button("Skip for Now") {
                        completeOnboarding()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}



struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appleHeadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color.primaryAccent)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.glassHighlight, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.glassBorder, lineWidth: 0.5)
            )
            .shadow(
                color: .glassShadow.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimation.glass, value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appleHeadline)
            .fontWeight(.medium)
            .foregroundColor(.primaryAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    Capsule()
                        .fill(GlassMaterial.secondary)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.glassHighlight, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.glassBorder, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(AppAnimation.glass, value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}