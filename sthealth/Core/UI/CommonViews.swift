//
//  CommonViews.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/01/25.
//

import SwiftUI

// MARK: - Locked Tab View
struct LockedTabView: View {
    let featureName: String
    let unlockDay: Int
    
    var body: some View {
        ZStack {
            Color.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "lock")
                    .font(.system(size: 60))
                    .foregroundColor(.secondaryText.opacity(0.5))
                
                Text("\(featureName) Locked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("This feature unlocks on Day \(unlockDay)")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Unlock Modal
struct UnlockModal: View {
    let title: String
    let message: String
    let buttonText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.primaryAccent)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { dismiss() }) {
                Text(buttonText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primaryAccent)
            .controlSize(.large)
        }
        .padding(32)
        .presentationDetents([.height(350)])
        .presentationBackground(Color.primaryBackground)
    }
}
