//
//  IntelligentWorkshopView.swift
//  Sthealth
//
//  Created by Claude Code on 6/28/25.
//

import SwiftUI
@preconcurrency import Combine

struct IntelligentWorkshopView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workshopEngine = IntelligentWorkshopEngine.shared
    @StateObject private var engagementTracker = EngagementTracker.shared
    
    @State private var messageText = ""
    @State private var showingCommitAlert = false
    @FocusState private var isInputFocused: Bool
    
    let hypothesis: Hypothesis
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Apple Glass Background
                LinearGradient(
                    colors: [
                        Color.primaryBackground,
                        Color.secondaryBackground.opacity(0.7),
                        Color.primaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Display the card at the top
                    SynapseCardView(hypothesis: hypothesis)
                        .scaleEffect(0.85)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                    
                    // Session progress indicator
                    if workshopEngine.isSessionActive {
                        sessionProgressHeader
                    }
                    
                    // Messages area
                    messagesScrollView
                    
                    // Input area
                    messageInputArea
                }
            }
            .navigationTitle("Workshop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { 
                        engagementTracker.recordInteraction(
                            context: .workshop,
                            item: "session_closed",
                            type: .abandon
                        )
                        dismiss() 
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Complete") {
                        showingCommitAlert = true
                    }
                    .disabled(!workshopEngine.isSessionActive || workshopEngine.messages.count < 3)
                    .foregroundColor(workshopEngine.messages.count >= 3 ? .primaryAccent : .gray)
                }
            }
            .alert("Complete Session", isPresented: $showingCommitAlert) {
                Button("Continue", role: .cancel) { }
                Button("Complete") {
                    Task {
                        if let insight = await workshopEngine.commitSession() {
                            // Could show success with insight
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("This will extract your insights and complete the workshop session. Are you ready?")
            }
        }
        .onAppear {
            startIntelligentSession()
        }
        .onDisappear {
            if workshopEngine.isSessionActive {
                // Track incomplete session
                engagementTracker.recordInteraction(
                    context: .workshop,
                    item: "session_incomplete",
                    type: .abandon,
                    metadata: ["message_count": "\(workshopEngine.messages.count)"]
                )
            }
        }
    }
    
    private var sessionProgressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Session Progress")
                    .font(.appleCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text("\(Int(workshopEngine.sessionProgress * 100))%")
                    .font(.appleCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryAccent)
            }
            
            ProgressView(value: workshopEngine.sessionProgress)
                .tint(.primaryAccent)
                .background(Color.glassSurface)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Rectangle()
                    .fill(GlassMaterial.secondary)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.glassHighlight, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if !workshopEngine.messages.isEmpty {
                        ForEach(workshopEngine.messages) { message in
                            IntelligentMessageBubble(message: message)
                                .id(message.id)
                        }
                    } else {
                        // Initial state
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(GlassMaterial.primary)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.glassBorder, lineWidth: 0.5)
                                    )
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(.primaryAccent)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Intelligent Workshop Session")
                                    .font(.appleHeadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Text("Let's explore your insight together with AI-guided therapeutic conversation")
                                    .font(.appleSubheadline)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 60)
                    }
                    
                    if workshopEngine.isProcessing {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.primaryAccent)
                            
                            Text("Processing your response...")
                                .font(.appleSubheadline)
                                .foregroundColor(.secondaryText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: workshopEngine.messages.count) {
                if let lastMessage = workshopEngine.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInputArea: some View {
        VStack(spacing: 8) {
            // Input field
            HStack(spacing: 12) {
                TextField("Share your thoughts...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.appleBody)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            GlassStyle.glassCard(cornerRadius: 20)
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.glassHighlight, .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .primaryAccent : .gray)
                }
                .disabled(!canSendMessage || workshopEngine.isProcessing)
                .scaleEffect(canSendMessage ? 1.0 : 0.9)
                .animation(AppAnimation.glass, value: canSendMessage)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Rectangle()
                        .fill(GlassMaterial.secondary)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .glassHighlight],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
            )
        }
    }
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        workshopEngine.isSessionActive
    }
    
    private func startIntelligentSession() {
        Task {
            await workshopEngine.startIntelligentSession(from: hypothesis)
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await workshopEngine.sendMessage(text)
        }
    }
}

// MARK: - Intelligent Message Bubble

struct IntelligentMessageBubble: View {
    let message: IntelligentMessage
    
    private var isUserMessage: Bool {
        message.role == .user
    }
    
    private var bubbleColor: Color {
        if isUserMessage {
            return .primaryAccent
        } else {
            switch message.emotionalTone {
            case .supportive:
                return .green.opacity(0.1)
            case .curious:
                return .blue.opacity(0.1)
            case .challenging:
                return .orange.opacity(0.1)
            case .empathetic:
                return .purple.opacity(0.1)
            case .celebratory:
                return .yellow.opacity(0.1)
            case .grounding:
                return .gray.opacity(0.1)
            }
        }
    }
    
    private var textColor: Color {
        isUserMessage ? .white : .primaryText
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUserMessage {
                Spacer(minLength: 60)
            } else {
                // Therapist avatar
                ZStack {
                    Circle()
                        .fill(GlassMaterial.secondary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.glassBorder, lineWidth: 0.5)
                        )
                    
                    Image(systemName: therapeuticIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryAccent)
                }
            }
            
            VStack(alignment: isUserMessage ? .trailing : .leading, spacing: 4) {
                if !isUserMessage, let intent = message.therapeuticIntent {
                    Text(intent.rawValue.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal, 8)
                }
                
                Text(message.content)
                    .font(.appleBody)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isUserMessage ? Color.primaryAccent : bubbleColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isUserMessage ? Color.clear : Color.clear)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isUserMessage ? .clear : .glassBorder, lineWidth: 0.5)
                    )
            }
            
            if !isUserMessage {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var therapeuticIcon: String {
        guard let intent = message.therapeuticIntent else { return "message" }
        
        switch intent {
        case .exploration:
            return "magnifyingglass"
        case .validation:
            return "checkmark.circle"
        case .challenge:
            return "questionmark.circle"
        case .reframe:
            return "arrow.triangle.2.circlepath"
        case .insight:
            return "lightbulb"
        case .integration:
            return "puzzlepiece"
        case .closure:
            return "checkmark.seal"
        }
    }
}

#Preview {
    NavigationStack {
        IntelligentWorkshopView(hypothesis: Hypothesis(
            id: 1,
            question_text: "You use productivity as a way to avoid dealing with uncomfortable emotions."
        ))
    }
}