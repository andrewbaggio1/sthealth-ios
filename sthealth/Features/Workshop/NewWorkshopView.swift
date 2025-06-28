//
//  NewWorkshopView.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/25/25.
//

import SwiftUI

struct NewWorkshopView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workshopManager = WorkshopManager.shared
    
    @State private var messageText = ""
    @State private var showingCommitAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesScrollView
                messageInputView
            }
            .background(Color.primaryBackground)
            .navigationTitle("Workshop Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Commit Insight") {
                        showingCommitAlert = true
                    }
                    .disabled(workshopManager.messages.isEmpty || workshopManager.isLoading)
                }
            }
            .alert("Commit Session", isPresented: $showingCommitAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Commit") {
                    Task {
                        let success = await workshopManager.commitSession()
                        if success {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("This will save your insights and end the workshop session. Are you sure?")
            }
        }
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(workshopManager.messages, id: \.id) { message in
                        MessageBubbleView(message: message)
                    }
                    
                    if workshopManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Thinking...")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    }
                }
                .padding()
            }
            .onChange(of: workshopManager.messages.count) {
                if let lastMessage = workshopManager.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInputView: some View {
        VStack(spacing: 8) {
            if let error = workshopManager.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .primaryAccent)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || workshopManager.isLoading)
            }
            .padding()
        }
        .background(Color.secondaryBackground)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        workshopManager.sendMessage(text)
    }
}

struct MessageBubbleView: View {
    let message: SessionMessage
    
    private var isUserMessage: Bool {
        message.senderType == "user"
    }
    
    var body: some View {
        HStack {
            if isUserMessage {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isUserMessage ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isUserMessage ? .white : .primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isUserMessage ? Color.primaryAccent : Color.secondaryBackground)
                    )
                
            }
            
            if !isUserMessage {
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else { return "" }
        
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NewWorkshopView()
}