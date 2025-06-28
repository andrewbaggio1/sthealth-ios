import SwiftUI
import AVFoundation
import PhotosUI

struct CaptureView: View {
    @StateObject private var viewModel = CaptureViewModel()
    @StateObject private var reflectionViewModel = ReflectionInputViewModel()
    @StateObject private var nudgeEngine = NudgeEngine.shared
    @StateObject private var workshopEngine = IntelligentWorkshopEngine.shared
    @State private var showProfile = false
    @State private var workshopHypothesis: Hypothesis?
    
    // Get user name from UserDefaults
    private var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "there"
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                
                VStack(spacing: 0) {
                    // Header with greeting and profile
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Main content with nudge integration
                    NudgeContainer {
                        VStack(spacing: 20) {
                            // Top - Glassy notepad reflection area
                            GlassyNotepadView(viewModel: reflectionViewModel)
                                .frame(height: geometry.size.height * 0.45)
                                .padding(.horizontal, 20)
                            
                            // Bottom - Stacked cards with proper sizing
                            VStack(spacing: 12) {
                                CardStackView(viewModel: viewModel, onWorkshopTrigger: { hypothesis in
                                    workshopHypothesis = hypothesis
                                })
                                .frame(height: 220)  // Smaller height to fit screen better
                                .padding(.horizontal, 20)
                                
                                // Swipe indicators below the deck
                                SwipeIndicatorView()
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(item: $workshopHypothesis) { hypothesis in
            IntelligentWorkshopView(hypothesis: hypothesis)
        }
        .onAppear {
            viewModel.fetchHypotheses()
            reflectionViewModel.requestPermissions()
            
            // Check for nudge opportunity when user opens app
            nudgeEngine.checkForNudgeOpportunity()
        }
        .onChange(of: workshopEngine.isSessionActive) { _, isActive in
            // Close workshop sheet when session ends
            if !isActive {
                workshopHypothesis = nil
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello \(userName)")
                    .font(.appleTitle)
                    .foregroundColor(.primaryText)
                    .fontWeight(.bold)
                
                Text("What's on your mind today?")
                    .font(.appleSubheadline)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Button(action: { showProfile = true }) {
                ZStack {
                    GlassStyle.glassButton(cornerRadius: 22)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primaryAccent)
                }
            }
            .scaleEffect(1.0)
            .animation(AppAnimation.glass, value: showProfile)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Glassy Notepad View
struct GlassyNotepadView: View {
    @ObservedObject var viewModel: ReflectionInputViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Apple Glass notepad background
            ZStack {
                GlassStyle.glassCard(cornerRadius: GlassStyle.cornerRadius)
                
                // Subtle glass highlight effect
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .glassHighlight,
                                .clear,
                                .clear,
                                .glassSurface
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 0) {
                // Main text area
                VStack(alignment: .leading, spacing: 8) {
                    if !viewModel.reflectionText.isEmpty || isTextFieldFocused {
                        HStack {
                            Text("Reflection")
                                .font(.appleCaption)
                                .foregroundColor(.tertiaryText)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    ZStack(alignment: .topLeading) {
                        // Placeholder when empty and not focused
                        if viewModel.reflectionText.isEmpty && !isTextFieldFocused {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Start writing your thoughts...")
                                    .font(.appleBody)
                                    .foregroundColor(.quaternaryText)
                                    .padding(.top, 8)
                                
                                Spacer()
                                
                                // Apple-style line guides with glass theme
                                VStack(spacing: 28) {
                                    ForEach(0..<5, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.glassBorder)
                                            .frame(height: 0.5)
                                    }
                                }
                                .opacity(0.4)
                            }
                        }
                        
                        // Text editor
                        TextEditor(text: $viewModel.reflectionText)
                            .font(.appleBody)
                            .focused($isTextFieldFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.primaryText)
                            .tint(.primaryAccent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                
                Spacer()
                
                // Action bar at bottom
                HStack(spacing: 16) {
                    // Voice recording button
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(viewModel.isRecording ? .errorAccent : .primaryAccent)
                            
                            if viewModel.isRecording {
                                Text("\(viewModel.recordingDuration, specifier: "%.0f")s")
                                    .font(.appleFootnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.errorAccent)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(GlassMaterial.secondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.glassBorder, lineWidth: 0.5)
                        )
                    }
                    .scaleEffect(viewModel.isRecording ? 1.05 : 1.0)
                    .animation(AppAnimation.glass, value: viewModel.isRecording)
                    
                    // Image upload button
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primaryAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(GlassMaterial.secondary)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.glassBorder, lineWidth: 0.5)
                            )
                    }
                    
                    Spacer()
                    
                    // Submit button
                    Button(action: viewModel.submitReflection) {
                        HStack(spacing: 8) {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            
                            Text(viewModel.isSubmitting ? "Saving..." : "Save")
                                .font(.appleSubheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(viewModel.canSubmit ? .white : .quaternaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(viewModel.canSubmit ? Color.primaryAccent : Color.glassSurface)
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.canSubmit ? .clear : .glassBorder, lineWidth: 0.5)
                                )
                        )
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                    .scaleEffect(viewModel.canSubmit ? 1.0 : 0.96)
                    .animation(AppAnimation.glass, value: viewModel.canSubmit)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Recording indicator
                if viewModel.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.errorAccent)
                            .frame(width: 6, height: 6)
                            .scaleEffect(viewModel.recordingPulse ? 1.3 : 0.8)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.recordingPulse)
                        
                        Text("Listening...")
                            .font(.appleCaption)
                            .fontWeight(.medium)
                            .foregroundColor(.errorAccent)
                    }
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.warningAccent)
                        Text(errorMessage)
                            .font(.appleCaption)
                            .foregroundColor(.warningAccent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(AppAnimation.glass, value: isTextFieldFocused)
        .animation(AppAnimation.fluid, value: viewModel.isRecording)
        .animation(AppAnimation.smooth, value: viewModel.errorMessage != nil)
    }
}

// MARK: - Card Stack View
struct CardStackView: View {
    @ObservedObject var viewModel: CaptureViewModel
    let onWorkshopTrigger: (Hypothesis) -> Void
    @State private var dragOffset = CGSize.zero
    @State private var isBeingDragged = false
    @State private var dragStartTime: Date?
    @State private var cardReturns: [String: Int] = [:]  // Track how many times user returns each card to center
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hypotheses.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    cardStackContent
                }
            }
        }
        .onChange(of: viewModel.hypotheses.count) { _, _ in
            // Reset drag when cards change
            dragOffset = .zero
            isBeingDragged = false
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.primaryAccent)
            Text("Loading insights...")
                .font(.appleSubheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cardStackContent: some View {
        ForEach(Array(viewModel.hypotheses.enumerated().reversed()), id: \.element.id) { index, hypothesis in
            let cardIndex = viewModel.hypotheses.count - 1 - index
            let isTopCard = cardIndex == viewModel.hypotheses.count - 1
            
            SynapseCardView(hypothesis: hypothesis)
                .scaleEffect(isTopCard ? 1.0 : 0.95 - Double(index) * 0.02)
                .offset(
                    x: isTopCard ? dragOffset.width : 0,
                    y: isTopCard ? dragOffset.height * 0.1 : CGFloat(index) * 3
                )
                .rotationEffect(.degrees(isTopCard ? Double(dragOffset.width / 20) : 0))
                .opacity(isTopCard ? 1.0 : 0.8 - Double(index) * 0.1)
                .zIndex(Double(cardIndex))
                .gesture(
                    isTopCard ? DragGesture()
                        .onChanged { value in
                            if dragStartTime == nil {
                                dragStartTime = Date()
                            }
                            dragOffset = value.translation
                            isBeingDragged = true
                        }
                        .onEnded { value in
                            handleSwipeGesture(value, for: hypothesis)
                        } : nil
                )
                .animation(AppAnimation.glass, value: dragOffset)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(GlassMaterial.secondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.glassBorder, lineWidth: 0.5)
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            
            VStack(spacing: 8) {
                Text("No insights yet")
                    .font(.appleHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Add a reflection above and we'll generate personalized insights for you")
                    .font(.appleSubheadline)
                    .foregroundColor(.tertiaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private func handleSwipeGesture(_ value: DragGesture.Value, for hypothesis: Hypothesis) {
        let threshold: CGFloat = 80
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )
        
        // Calculate hesitation time
        let hesitationTime = dragStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        if abs(value.translation.width) > threshold || abs(velocity.width) > 500 {
            // Record final decision with hesitation time
            if hesitationTime > 2.0 {  // More than 2 seconds = significant hesitation
                viewModel.recordCardHesitation(hypothesis: hypothesis, hesitationTime: hesitationTime)
            }
            
            if value.translation.width > 0 {
                // Check if it's a deep swipe right for workshop
                if abs(value.translation.width) > threshold * 2 || abs(velocity.width) > 1000 {
                    // Deep swipe right - Trigger workshop
                    onWorkshopTrigger(hypothesis)
                    viewModel.deepSwipeRight(hypothesis: hypothesis)
                    animateCardExit(.trailing)
                } else {
                    // Regular swipe right - Yes
                    viewModel.swipeRight(hypothesis: hypothesis)
                    animateCardExit(.trailing)
                }
            } else {
                // Swipe left - No
                viewModel.swipeLeft(hypothesis: hypothesis)
                animateCardExit(.leading)
            }
        } else {
            // Return to center - user is reconsidering
            let cardKey = "\(hypothesis.id)"
            cardReturns[cardKey, default: 0] += 1
            
            // Record reconsideration behavior
            if cardReturns[cardKey]! > 1 {
                viewModel.recordCardReconsideration(hypothesis: hypothesis, rereadCount: cardReturns[cardKey]!)
            }
            
            withAnimation(AppAnimation.glass) {
                dragOffset = .zero
                isBeingDragged = false
            }
        }
        
        // Reset drag timing
        dragStartTime = nil
    }
    
    private func animateCardExit(_ edge: Edge) {
        let exitOffset: CGFloat = edge == .leading ? -400 : 400
        
        withAnimation(AppAnimation.smooth) {
            dragOffset = CGSize(width: exitOffset, height: -100)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dragOffset = .zero
            isBeingDragged = false
        }
    }
}

// MARK: - Swipe Indicator View
struct SwipeIndicatorView: View {
    var body: some View {
        HStack(spacing: 20) {
            // Left arrow (no)
            Image(systemName: "arrow.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.tertiaryText)
            
            Spacer()
            
            // Center "swipe" text
            Text("swipe")
                .font(.appleSubheadline)
                .fontWeight(.medium)
                .foregroundColor(.tertiaryText)
                .opacity(0.7)
            
            Spacer()
            
            // Right arrow (yes)
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.tertiaryText)
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 16)
    }
}

#Preview {
    CaptureView()
}