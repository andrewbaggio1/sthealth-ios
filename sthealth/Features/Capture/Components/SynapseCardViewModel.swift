//
//  SynapseCardViewModel.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/16/25.
//

import SwiftUI
import SwiftData
import Combine

enum SwipeResult {
    case reject
    case accept
    case commitToWorkshop
}

@MainActor
class SynapseCardViewModel: ObservableObject {
    private let modelContext: ModelContext
    let navigationSubject = PassthroughSubject<AppTab, Never>()
    private let workshopManager = WorkshopManager.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func handleSwipe(card: SynapseCard, result: SwipeResult) {
        card.statusRawValue = SwipeStatus.dismissed.rawValue
        
        let areRelated: Bool
        switch result {
        case .reject:
            areRelated = false
        case .accept, .commitToWorkshop:
            areRelated = true
        }

        saveFeedback(for: card, userAgrees: areRelated)
        
        if result == .commitToWorkshop {
            print("User committed to exploring in workshop.")
            if let hypothesis = card.hypothesis {
                workshopManager.startSession(hypothesisId: hypothesis.id)
            }
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func saveFeedback(for card: SynapseCard, userAgrees: Bool) {
        let sourceIDs = card.sourceMomentIDs
        guard sourceIDs.count == 2 else { return }
        
        guard let momentA = getMoment(with: sourceIDs[0]), let momentB = getMoment(with: sourceIDs[1]) else { return }
        guard let vectorA = momentA.cognitiveStateVector, let vectorB = momentB.cognitiveStateVector else { return }
        
        let feedback = SynapticFeedback(vectorA: vectorA, vectorB: vectorB, areRelated: userAgrees)
        modelContext.insert(feedback)
        
        try? modelContext.save()
        print("Feedback saved: \(userAgrees)")
    }
    
    private func getMoment(with id: UUID) -> Moment? {
        let descriptor = FetchDescriptor<Moment>(predicate: #Predicate { $0.id == id })
        return (try? modelContext.fetch(descriptor))?.first
    }
}
