//
//  WorkbenchView.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/16/25.
//

import SwiftUI
import SwiftData

struct WorkbenchSubject {
    let title: String
    let description: String?
    
    init(title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }
}

// MARK: - Main Workbench View
struct WorkbenchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkbenchTool.orderIndex) private var tools: [WorkbenchTool]
    @StateObject private var viewModel: WorkbenchViewModel

    init(subject: WorkbenchSubject) {
        _viewModel = StateObject(wrappedValue: WorkbenchViewModel(subject: subject))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                subjectHeader

                if viewModel.selectedTool == nil {
                    toolSelectionList
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    activeSessionView
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .trailing).combined(with: .opacity)))
                }
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationTitle("Workbench")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .onAppear {
                viewModel.modelContext = modelContext
            }
            .animation(AppAnimation.gentle, value: viewModel.selectedTool)
        }
    }

    private var subjectHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ANALYZING SUBJECT").font(.caption.weight(.bold)).foregroundColor(.secondaryText)
            Text(viewModel.subject.title).font(.body).lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryBackground)
    }

    private var toolSelectionList: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Select a Tool").font(.title3.weight(.bold)).padding(.top)
                ForEach(tools) { tool in
                    ToolSelectionCard(tool: tool) {
                        viewModel.selectTool(tool)
                    }
                }
            }
            .padding()
        }
    }

    private var activeSessionView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(viewModel.sessionSteps) { step in
                        WorkbenchStepView(step: step)
                    }

                    if let currentPrompt = viewModel.currentPrompt {
                        ActivePromptView(
                            prompt: currentPrompt,
                            response: $viewModel.currentResponse,
                            isSubmitting: viewModel.isWaitingForAI,
                            onSubmit: viewModel.submitResponse
                        ).id("activePrompt")
                    }

                    if viewModel.isComplete {
                        CompletionView(
                            summary: viewModel.summary,
                            insightTitle: $viewModel.insightTitle,
                            onSave: { saveInsight() }
                        ).id("completionView")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.sessionSteps.count) {
                withAnimation { proxy.scrollTo("activePrompt", anchor: .bottom) }
            }
            .onChange(of: viewModel.isComplete) {
                if viewModel.isComplete {
                    withAnimation { proxy.scrollTo("completionView", anchor: .bottom) }
                }
            }
        }
    }

    private func saveInsight() {
        Task {
            await viewModel.saveInsightAsCoreSchema()
            dismiss()
        }
    }
}

// MARK: - Workbench Subviews
private struct ToolSelectionCard: View {
    let tool: WorkbenchTool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: tool.icon).font(.title2).foregroundColor(.primaryAccent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name).font(.body.weight(.medium)).foregroundColor(.primaryText)
                    Text(tool.toolDescription).font(.caption).foregroundColor(.secondaryText) // <-- FIXED
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondaryText)
            }
            .padding().background(Color.secondaryBackground).cornerRadius(12)
        }.buttonStyle(.plain)
    }
}

private struct WorkbenchStepView: View {
    let step: WorkbenchStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(step.prompt).font(.body.weight(.semibold)).foregroundColor(.secondaryText)

            if let response = step.response {
                Text(response)
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primaryAccent.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

private struct ActivePromptView: View {
    let prompt: String
    @Binding var response: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt).font(.body.weight(.semibold))

            TextEditor(text: $response)
                .focused($isFocused)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.secondaryBackground)
                .cornerRadius(8)

            Button(action: onSubmit) {
                if isSubmitting { ProgressView() } else { Text("Continue") }
            }
            .buttonStyle(.borderedProminent).tint(.primaryAccent)
            .disabled(response.isEmpty || isSubmitting)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding().background(Color.primaryBackground)
        .onAppear { isFocused = true }
    }
}

private struct CompletionView: View {
    let summary: String
    @Binding var insightTitle: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(.primaryAccent)
            Text("Insight Uncovered").font(.title3.weight(.bold))
            Text(summary).font(.body).multilineTextAlignment(.center)

            TextField("Name this new insight...", text: $insightTitle)
                .padding().background(Color.secondaryBackground).cornerRadius(8)

            Button("Save to Cognitive Atlas", action: onSave)
                .buttonStyle(.borderedProminent).tint(.primaryAccent).controlSize(.large)
                .disabled(insightTitle.isEmpty)
        }
        .padding().background(Color.green.opacity(0.1)).cornerRadius(16)
    }
}

// MARK: - Workbench View Model
@MainActor
final class WorkbenchViewModel: ObservableObject {
    @Published var selectedTool: WorkbenchTool?
    @Published var sessionSteps: [WorkbenchStep] = []
    @Published var currentPrompt: String?
    @Published var currentResponse = ""
    @Published var isWaitingForAI = false
    @Published var isComplete = false
    @Published var summary = ""
    @Published var insightTitle = ""

    let subject: WorkbenchSubject
    var modelContext: ModelContext?
    private var toolChain: WorkbenchToolChain?
    private var currentStepIndex = 0
    private var sessionVariables: [String: String] = [:]

    init(subject: WorkbenchSubject) {
        self.subject = subject
    }

    func selectTool(_ tool: WorkbenchTool) {
        self.selectedTool = tool

        if let data = tool.promptChainJSON.data(using: .utf8),
           let chain = try? JSONDecoder().decode(WorkbenchToolChain.self, from: data) {
            self.toolChain = chain
            sessionVariables["subject"] = subject.title
            self.currentPrompt = substituteVariables(in: chain.initial_prompt)
        }
    }

    func submitResponse() {
        guard !currentResponse.isEmpty, !isWaitingForAI else { return }

        isWaitingForAI = true
        let userResponse = currentResponse

        sessionSteps.append(WorkbenchStep(prompt: currentPrompt ?? "", response: userResponse))
        if let variable = toolChain?.steps[currentStepIndex].variable {
            sessionVariables[variable] = userResponse
        }

        currentResponse = ""
        currentPrompt = nil

        Task {
            await processNextStep()
            isWaitingForAI = false
        }
    }

    func saveInsightAsCoreSchema() async {
        guard let modelContext, isComplete, !insightTitle.isEmpty else { return }

        let coreSchema = CoreSchema(title: insightTitle, summary: summary, status: .active)

        // Placeholder for a potential future CognitiveEngine function
        // if let quadrant = await CognitiveEngine.shared.classifyQuadrant(for: summary) {
        //     coreSchema.quadrant = quadrant
        // }

        modelContext.insert(coreSchema)
        try? modelContext.save()
    }

    private func processNextStep() async {
        guard let chain = toolChain else { return }

        currentStepIndex += 1
        guard currentStepIndex < chain.steps.count else {
            await generateSummary(chain: chain)
            return
        }

        let step = chain.steps[currentStepIndex]

        switch step.type {
        case "user_input":
            currentPrompt = substituteVariables(in: step.prompt ?? "Continue...")

        case "ai_prompt":
            let prompt = substituteVariables(in: step.prompt ?? "")
            let context = sessionSteps.map { "\($0.prompt)\n> \($0.response ?? "")" }.joined(separator: "\n\n")

            if let response = await CognitiveEngine.shared.processWorkbenchStep(toolName: chain.name, sessionContext: context, currentStep: prompt) {
                sessionSteps.append(WorkbenchStep(prompt: prompt, response: nil))
                if let variable = step.variable { sessionVariables[variable] = response }
                await processNextStep()
            }

        case "ai_summary":
            await generateSummary(chain: chain)

        default:
            print("Unknown workshop step type: \(step.type)")
        }
    }

    private func generateSummary(chain: WorkbenchToolChain) async {
        let summaryPrompt = chain.steps.first(where: { $0.type == "ai_summary" })?.prompt ?? "Summarize the key insight from this session in 2-3 sentences."
        let context = sessionSteps.map { "\($0.prompt)\n> \($0.response ?? "")" }.joined(separator: "\n\n")

        if let summaryText = await CognitiveEngine.shared.processWorkbenchStep(toolName: chain.name, sessionContext: context, currentStep: summaryPrompt) {
            self.summary = summaryText
            self.isComplete = true
            self.currentPrompt = nil
        }
    }

    private func substituteVariables(in text: String) -> String {
        var result = text
        for (key, value) in sessionVariables {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

struct WorkbenchStep: Identifiable {
    let id = UUID()
    let prompt: String
    let response: String?
}
