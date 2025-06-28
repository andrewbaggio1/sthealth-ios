//
//  CognitiveModels.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/01/25.
//

import SwiftData
import Foundation

// MARK: - Core Enums for Type Safety

enum SwipeStatus: String, Codable, CaseIterable {
    case pending
    case acknowledged
    case dismissed
}

enum Modality: String, Codable, CaseIterable {
    case text
    case voice
    case image
}

enum ConceptType: String, Codable, CaseIterable {
    case abstract
    case person
    case activity
    case emotion
    case belief
    case pattern
}

enum CoreSchemaStatus: String, Codable, CaseIterable {
    case active
    case dormant
    case resolved
    case transforming
}

enum NotificationInteractionType: String, Codable, CaseIterable {
    case shown
    case dismissed
    case tapped
    case followedByRelevantReflection
}

// MARK: - Primary Data Models

@Model
final class Moment {
    @Attribute(.unique) var id: UUID
    var text: String
    var resonatedText: String?
    var timestamp: Date
    private var modalityRawValue: String
    var modality: Modality {
        get { Modality(rawValue: modalityRawValue) ?? .text }
        set { modalityRawValue = newValue.rawValue }
    }
    
    @Relationship(inverse: \CognitiveTag.relatedMoments)
    var cognitiveTags: [CognitiveTag]?
    
    @Attribute(.externalStorage) var cognitiveStateVectorData: Data?
    var cognitiveStateVector: [Double]? {
        get { (try? JSONDecoder().decode([Double].self, from: cognitiveStateVectorData ?? Data())) ?? [] }
        set { cognitiveStateVectorData = try? JSONEncoder().encode(newValue) }
    }
    
    init(text: String, timestamp: Date, modality: Modality) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.modalityRawValue = modality.rawValue
    }
}

@Model
final class CognitiveTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRawValue: String
    var type: ConceptType {
        get { ConceptType(rawValue: typeRawValue) ?? .abstract }
        set { typeRawValue = newValue.rawValue }
    }
    var createdAt: Date
    
    var relatedMoments: [Moment]?
    
    init(name: String, type: ConceptType) {
        self.id = UUID()
        self.name = name
        self.typeRawValue = type.rawValue
        self.createdAt = Date()
    }
}

@Model
final class CoreSchema {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    private var statusRawValue: String
    var status: CoreSchemaStatus {
        get { CoreSchemaStatus(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }
    var creationDate: Date
    
    var quadrant: String?
    var centralityScore: Double?
    var valenceScore: Double?
    var positionX: Double
    var positionY: Double
    
    var neuralPathway: NeuralPathway?
    
    init(title: String, summary: String, status: CoreSchemaStatus = .active) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.statusRawValue = status.rawValue
        self.creationDate = Date()
        self.positionX = 0
        self.positionY = 0
    }
}

@Model
final class NeuralPathway {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String?
    var createdAt: Date
    
    @Relationship(inverse: \CoreSchema.neuralPathway)
    var coreSchemas: [CoreSchema]?
    
    init(title: String, summary: String? = nil) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.createdAt = Date()
    }
}

// MARK: - User-Defined Anchor Models

@Model
final class CompassValue {
    @Attribute(.unique) var id: UUID
    var name: String
    var userDescription: String?
    var createdAt: Date
    
    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.userDescription = description
        self.createdAt = Date()
    }
}

@Model
final class CompassGoal {
    @Attribute(.unique) var id: UUID
    var title: String
    var userDescription: String?
    var createdAt: Date
    var isActive: Bool
    
    init(title: String, description: String? = nil) {
        self.id = UUID()
        self.title = title
        self.userDescription = description
        self.createdAt = Date()
        self.isActive = true
    }
}

// MARK: - Card & Notification Models

@Model
final class SynapseCard {
    @Attribute(.unique) var id: UUID
    var questionText: String
    var statusRawValue: String
    var status: SwipeStatus {
        get { SwipeStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }
    var createdAt: Date
    var primaryEmotion: String?
    var secondaryEmotion: String?
    var hypothesisId: String?
    
    @Attribute(.externalStorage) private var sourceMomentIDsData: Data?
    var sourceMomentIDs: [UUID] {
        get { (try? JSONDecoder().decode([UUID].self, from: sourceMomentIDsData ?? Data())) ?? [] }
        set { sourceMomentIDsData = try? JSONEncoder().encode(newValue) }
    }
    
    @Attribute(.externalStorage) private var hypothesisData: Data?
    var hypothesis: Hypothesis? {
        get { try? JSONDecoder().decode(Hypothesis.self, from: hypothesisData ?? Data()) }
        set { hypothesisData = try? JSONEncoder().encode(newValue) }
    }
    
    init(questionText: String, sourceMomentIDs: [UUID], primaryEmotion: String?, secondaryEmotion: String?) {
        self.id = UUID()
        self.questionText = questionText
        self.statusRawValue = SwipeStatus.pending.rawValue
        self.createdAt = Date()
        self.primaryEmotion = primaryEmotion
        self.secondaryEmotion = secondaryEmotion
        self.sourceMomentIDs = sourceMomentIDs
    }
    
    init(hypothesis: Hypothesis, sourceMomentIDs: [UUID] = []) {
        self.id = UUID()
        self.questionText = hypothesis.question_text
        self.statusRawValue = SwipeStatus.pending.rawValue
        self.createdAt = Date()
        self.primaryEmotion = nil
        self.secondaryEmotion = nil
        self.sourceMomentIDs = sourceMomentIDs
        self.hypothesisId = String(hypothesis.id)
        self.hypothesis = hypothesis
    }
}

@Model
final class Notification {
    @Attribute(.unique) var id: UUID
    var text: String
    var triggerContext: String
    var predictedState: String
    var createdAt: Date
    private var interactionRawValue: String?
    var interaction: NotificationInteractionType? {
        get {
            guard let rawValue = interactionRawValue else { return nil }
            return NotificationInteractionType(rawValue: rawValue)
        }
        set { interactionRawValue = newValue?.rawValue }
    }
    
    init(text: String, triggerContext: String, predictedState: String) {
        self.id = UUID()
        self.text = text
        self.triggerContext = triggerContext
        self.predictedState = predictedState
        self.createdAt = Date()
    }
}

@Model
final class AlignmentCard {
    @Attribute(.unique) var id: UUID
    var observation: String
    var isAlignment: Bool
    var relatedValueOrGoal: String
    var createdAt: Date
    var statusRawValue: String
    var status: SwipeStatus {
        get { SwipeStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }
    
    init(observation: String, isAlignment: Bool, relatedValueOrGoal: String) {
        self.id = UUID()
        self.observation = observation
        self.isAlignment = isAlignment
        self.relatedValueOrGoal = relatedValueOrGoal
        self.createdAt = Date()
        self.statusRawValue = SwipeStatus.pending.rawValue
    }
}

// MARK: - Configuration Models

@Model
final class WorkbenchTool {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var toolDescription: String // Renamed from 'description'
    var promptChainJSON: String
    var orderIndex: Int
    
    // FIXED: The init now correctly uses 'toolDescription' as its parameter label
    init(name: String, icon: String, toolDescription: String, promptChainJSON: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.toolDescription = toolDescription
        self.promptChainJSON = promptChainJSON
        self.orderIndex = orderIndex
    }
}

// MARK: - Utility Models

@Model
final class SynapticFeedback {
    @Attribute(.unique) var id: UUID
    var areRelated: Bool
    var timestamp: Date
    
    @Attribute(.externalStorage) private var vectorAData: Data?
    var vectorA: [Double] {
        get { (try? JSONDecoder().decode([Double].self, from: vectorAData ?? Data())) ?? [] }
        set { vectorAData = try? JSONEncoder().encode(newValue) }
    }
    
    @Attribute(.externalStorage) private var vectorBData: Data?
    var vectorB: [Double] {
        get { (try? JSONDecoder().decode([Double].self, from: vectorBData ?? Data())) ?? [] }
        set { vectorBData = try? JSONEncoder().encode(newValue) }
    }
    
    init(vectorA: [Double], vectorB: [Double], areRelated: Bool) {
        self.id = UUID()
        self.areRelated = areRelated
        self.timestamp = Date()
        self.vectorA = vectorA
        self.vectorB = vectorB
    }
}

// MARK: - Global Schema Definition
let fullSchema = Schema([
    Moment.self,
    CognitiveTag.self,
    CoreSchema.self,
    NeuralPathway.self,
    CompassValue.self,
    CompassGoal.self,
    SynapseCard.self,
    AlignmentCard.self,
    Notification.self,
    WorkbenchTool.self,
    SynapticFeedback.self,
])
