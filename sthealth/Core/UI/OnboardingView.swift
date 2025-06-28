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
                        startSplashTimer()
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
                AuthenticationView {
                    requestBiometricAuthentication()
                }
            
            case .completed:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentState)
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
                
                VStack(spacing: 8) {
                    Text("sthealth")
                        .font(.appleTitle)
                        .fontWeight(.thin)
                        .foregroundColor(.primaryText)
                    
                    Text("Cognitive Wellness")
                        .font(.appleSubheadline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondaryText)
                }
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
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 48) {
                VStack(spacing: 16) {
                    Text("Welcome to sthealth")
                        .font(.appleLargeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's start your cognitive wellness journey")
                        .font(.appleHeadline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("What should we call you?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        TextField("First Name", text: $userName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.appleBody)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                ZStack {
                                    GlassStyle.glassCard(cornerRadius: 12)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.glassHighlight, .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            )
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    onSubmit()
                                }
                            }
                    }
                    .padding(.horizontal, 40)
                    
                    Button("Continue") {
                        onSubmit()
                    }
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authManager.isLoading)
                    .buttonStyle(GlassButtonStyle())
                    .padding(.horizontal, 40)
                    
                    if authManager.isLoading {
                        ProgressView("Registering...")
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
                    Image(systemName: icon)
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 16) {
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text(description)
                            .font(.title3)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
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
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "faceid")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 16) {
                        Text("Secure Your Data")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("Your cognitive insights are deeply personal. Let's secure them with biometric authentication.")
                            .font(.title3)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 32)
                    }
                }
                
                Button("Enable Security") {
                    onAuthenticate()
                }
                .buttonStyle(GlassButtonStyle())
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