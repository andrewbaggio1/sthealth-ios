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
    @State private var showWorkshopSheet = false
    
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
                        VStack(spacing: 32) {
                            // Top - Glassy notepad reflection area
                            GlassyNotepadView(viewModel: reflectionViewModel)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)  // Add extra padding to move it up from cards
                            
                            // Bottom - Stacked cards with proper sizing
                            // Cards with dynamic height based on available space
                            CardStackView(viewModel: viewModel, onWorkshopTrigger: { hypothesis in
                                workshopHypothesis = hypothesis
                            })
                            .frame(height: min(340, geometry.size.height * 0.45))  // Adjusted for smaller cards
                        }
                    }
                    
                    Spacer(minLength: 10)
                }
                
                // Floating Action Button for Workshop
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showWorkshopSheet = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.primaryAccent)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(item: $workshopHypothesis) { hypothesis in
            IntelligentWorkshopView(hypothesis: hypothesis)
        }
        .sheet(isPresented: $showWorkshopSheet) {
            WorkshopView()
        }
        .onAppear {
            viewModel.fetchHypotheses()
            reflectionViewModel.requestPermissions()
            
            // Check for nudge opportunity when user opens app
            nudgeEngine.checkForNudgeOpportunity()
            
            // Force show nudge for testing (temporary)
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                nudgeEngine.forceShowNudge()
            }
            #endif
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
            // Apple Glass notepad background with higher opacity
            ZStack {
                // More opaque background
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(Color.white.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                            .fill(GlassMaterial.secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                            .stroke(.white.opacity(0.3), lineWidth: GlassStyle.borderWidth)
                    )
                    .shadow(color: .glassShadow, radius: GlassStyle.shadowRadius, x: GlassStyle.shadowOffset.width, y: GlassStyle.shadowOffset.height)
                
                // Subtle glass highlight effect
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .glassHighlight.opacity(0.3),
                                .clear,
                                .clear,
                                .glassSurface.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 0) {
                // Reflection label at the very top
                HStack {
                    Text("Reflection")
                        .font(.appleCaption)
                        .foregroundColor(.tertiaryText)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                
                // Text input area
                ZStack(alignment: .topLeading) {
                    // Placeholder when empty and not focused
                    if viewModel.reflectionText.isEmpty && !isTextFieldFocused {
                        Text("Start writing your thoughts...")
                            .font(.appleBody)
                            .foregroundColor(.quaternaryText)
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                    }
                    
                    // Text editor with dynamic height
                    TextEditor(text: $viewModel.reflectionText)
                        .font(.appleBody)
                        .focused($isTextFieldFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(.primaryText)
                        .tint(.primaryAccent)
                        .padding(.horizontal, 16)
                        .frame(minHeight: viewModel.reflectionText.isEmpty ? 40 : 35, maxHeight: 80)
                        .fixedSize(horizontal: false, vertical: !viewModel.reflectionText.isEmpty)
                }
                
                Spacer(minLength: 4)
                
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
                        if viewModel.isRecording {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.errorAccent)
                                
                                Text("\(viewModel.recordingDuration, specifier: "%.0f")s")
                                    .font(.appleFootnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.errorAccent)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(GlassMaterial.secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.glassBorder, lineWidth: 0.5)
                            )
                        } else {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primaryAccent)
                                .frame(width: 44, height: 44)
                                .background(GlassMaterial.secondary)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.glassBorder, lineWidth: 0.5)
                                )
                        }
                    }
                    .scaleEffect(viewModel.isRecording ? 1.05 : 1.0)
                    .animation(AppAnimation.smooth, value: viewModel.isRecording)
                    
                    // Image upload button
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primaryAccent)
                            .frame(width: 44, height: 44)
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
                        .padding(.horizontal, viewModel.isSubmitting ? 24 : 20)
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
                    .opacity(viewModel.canSubmit ? 1.0 : 0.8)
                    .scaleEffect(viewModel.canSubmit && !viewModel.isSubmitting ? 1.0 : 0.98)
                    .animation(AppAnimation.fluid, value: viewModel.canSubmit)
                    .animation(AppAnimation.fluid, value: viewModel.isSubmitting)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.top, 4)
                
                // Recording indicator
                if viewModel.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.errorAccent)
                            .frame(width: 6, height: 6)
                            .scaleEffect(viewModel.recordingPulse ? 1.3 : 0.8)
                            .animation(viewModel.isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: viewModel.recordingPulse)
                        
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
        .animation(AppAnimation.smooth, value: viewModel.isRecording)
        .animation(AppAnimation.smooth, value: viewModel.errorMessage != nil)
        .animation(AppAnimation.smooth, value: isTextFieldFocused)
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
        ZStack(alignment: .center) {
            // Navigation indicators for top card
            if !viewModel.hypotheses.isEmpty {
                // Workshop indicator above cards
                VStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.tertiaryText)
                    Text("workshop")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.tertiaryText)
                }
                .offset(y: -180) // Position well above cards
                .zIndex(1001)
                
                // Left/right indicators aligned with card middle
                HStack(spacing: 0) {
                    // Left X - Red
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemRed))
                        .padding(12)
                        .background(Circle().fill(Color.glassSurface))
                        .overlay(Circle().stroke(Color.glassBorder, lineWidth: 0.5))
                        .offset(x: -10) // Move left
                    
                    Spacer()
                    
                    // Right checkmark - Green
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGreen))
                        .padding(12)
                        .background(Circle().fill(Color.glassSurface))
                        .overlay(Circle().stroke(Color.glassBorder, lineWidth: 0.5))
                        .offset(x: 10) // Move right
                }
                .frame(width: UIScreen.main.bounds.width - 40)
                .zIndex(1000)
            }
            
            ForEach(Array(viewModel.hypotheses.prefix(4).enumerated().reversed()), id: \.element.id) { index, hypothesis in
            let displayCount = min(viewModel.hypotheses.count, 4)
            let cardIndex = displayCount - 1 - index
            let isTopCard = index == 0
            
            SynapseCardView(hypothesis: hypothesis)
                .scaleEffect(isTopCard ? 1.0 : max(0.85, 0.95 - Double(index) * 0.02))
                .offset(
                    x: isTopCard ? dragOffset.width : 0,
                    y: isTopCard ? dragOffset.height * 0.1 : CGFloat(index) * 8
                )
                .rotationEffect(.degrees(isTopCard ? min(max(Double(dragOffset.width / 20), -45), 45) : 0))
                .opacity(isTopCard ? 1.0 : max(0.3, 0.8 - Double(index) * 0.1))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        let horizontalThreshold: CGFloat = 80
        let verticalThreshold: CGFloat = 100
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )
        
        // Calculate hesitation time
        let hesitationTime = dragStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Check for upward swipe first (workshop)
        if value.translation.height < -verticalThreshold || velocity.height < -500 {
            // Swipe up - Trigger workshop
            onWorkshopTrigger(hypothesis)
            viewModel.deepSwipeRight(hypothesis: hypothesis) // Using existing method for workshop
            animateCardExit(.top)
        } else if abs(value.translation.width) > horizontalThreshold || abs(velocity.width) > 500 {
            // Record final decision with hesitation time
            if hesitationTime > 2.0 {  // More than 2 seconds = significant hesitation
                viewModel.recordCardHesitation(hypothesis: hypothesis, hesitationTime: hesitationTime)
            }
            
            if value.translation.width > 0 {
                // Swipe right - Yes
                viewModel.swipeRight(hypothesis: hypothesis)
                animateCardExit(.trailing)
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
        let exitOffset: CGFloat = edge == .leading ? -400 : (edge == .trailing ? 400 : 0)
        let verticalOffset: CGFloat = edge == .top ? -600 : -100
        
        withAnimation(AppAnimation.smooth) {
            dragOffset = CGSize(width: exitOffset, height: verticalOffset)
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
        HStack(spacing: 16) {
            Text("swipe to decide")
                .font(.appleCaption)
                .fontWeight(.medium)
                .foregroundColor(.quaternaryText)
                .opacity(0.6)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CaptureView()
}