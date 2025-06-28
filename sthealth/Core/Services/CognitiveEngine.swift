//
//  CognitiveEngine.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/01/25.
//

import Foundation
import UIKit

// MARK: - API Communication Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int
    let response_format: ResponseFormat?
    
    struct ImageContent: Codable {
        let type: String
        let text: String?
        let image_url: ImageURL?
        
        struct ImageURL: Codable {
            let url: String
        }
    }
    
    struct MultimodalMessage: Codable {
        let role: String
        let content: [ImageContent]
    }
}
struct OpenAIMessage: Codable { let role: String; let content: String }
struct ResponseFormat: Codable { let type: String }
struct OpenAIResponse: Codable { struct Choice: Codable { let message: OpenAIMessage }; let choices: [Choice] }
struct EmbeddingRequest: Codable { let input: [String]; let model: String }
struct EmbeddingResponse: Codable { struct EmbeddingData: Codable { let embedding: [Double] }; let data: [EmbeddingData] }

// MARK: - Structured AI Response Models
struct EmotionAnalysis: Codable {
    let primary: EmotionResult
    let secondary: EmotionResult
}
struct EmotionResult: Codable {
    let emotion: String
    let intensity: Double
}

struct EntityExtraction: Codable {
    let concepts: [ExtractedConcept]
    let people: [String]
    let emotions: [String]
}
struct ExtractedConcept: Codable {
    let name: String
    let type: ConceptType
}

struct AlignmentAnalysis: Codable {
    let alignment: AlignmentResult?
    let misalignment: AlignmentResult?
}
struct AlignmentResult: Codable {
    let observation: String
    let related_value: String?
    let related_goal: String?
}

struct ThreadSuggestion: Codable {
    let theme: String
    let confidence: Double
}

struct WorkbenchToolChain: Codable {
    struct Step: Codable {
        let type: String
        let prompt: String?
        let variable: String?
    }
    let name: String
    let initial_prompt: String
    let steps: [Step]
}

// MARK: - Cognitive Engine
final class CognitiveEngine {
    static let shared = CognitiveEngine()
    
    // PRODUCTION: API key securely retrieved from backend
    private let apiKey: String = "" // Removed for security - use backend proxy in production
    private let chatEndpoint = "https://api.openai.com/v1/chat/completions"
    private let embeddingEndpoint = "https://api.openai.com/v1/embeddings"
    
    private let defaultModel = "gpt-4o-mini"
    
    private init() {}
    
    // MARK: - Core Pipeline
    
    func generateCognitiveStateVector(for text: String) async -> [Double]? {
        guard !text.isEmpty else { return nil }
        let requestBody = EmbeddingRequest(input: [text], model: "text-embedding-3-small")
        
        do {
            let data = try await makeAPIRequest(endpoint: embeddingEndpoint, body: requestBody)
            let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
            return response.data.first?.embedding
        } catch {
            print("Failed to generate embedding: \(error)")
            return nil
        }
    }
    
    func resonateText(for moment: Moment, withHistory historySummary: String) async -> String? {
        let systemPrompt = "You are a psychological insight engine. Your task is to expand the user's raw reflection into a richer paragraph. Articulate potential underlying feelings, unspoken assumptions, and connections to their known themes based on their history. Adopt their unique voice and style."
        let userPrompt = """
        USER HISTORY:
        \(historySummary)
        ---
        LATEST REFLECTION (\(moment.modality.rawValue)):
        "\(moment.text)"
        ---
        YOUR EXPANDED, RESONATED TEXT:
        """
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.6, max_tokens: 400, response_format: nil)
        
        return try? await makeChatRequest(with: requestBody)
    }

    func extractEntities(from resonatedText: String) async -> EntityExtraction? {
        let systemPrompt = """
        Extract key entities from the text. Categorize concepts into 'abstract', 'belief', or 'pattern'. Your response MUST be a valid JSON object adhering to this exact structure:
        {
            "concepts": [{"name": "Imposter Syndrome", "type": "abstract"}],
            "people": ["Mom", "My Boss"],
            "emotions": ["Anxiety", "Joy"]
        }
        """
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: resonatedText)
        ], temperature: 0, max_tokens: 500, response_format: ResponseFormat(type: "json_object"))

        return await makeStructuredRequest(with: requestBody)
    }
    
    // MARK: - Insight & Card Generation

    func generateInsight(between momentA: Moment, and momentB: Moment) async -> (text: String, emotions: EmotionAnalysis?)? {
        let systemPrompt = "You are an Assumption Engine. Analyze two user reflections and generate a SINGLE, gentle, insightful assumption about the underlying connection. The statement MUST be under 150 characters, framed as an observation (e.g., 'It seems that...'). Respond with ONLY the assumption statement."
        let userPrompt = "Reflection 1: \"\(momentA.resonatedText ?? momentA.text)\"\nReflection 2: \"\(momentB.resonatedText ?? momentB.text)\""
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.7, max_tokens: 60, response_format: nil)
        
        guard let assumptionText = try? await makeChatRequest(with: requestBody) else { return nil }
        let trimmedText = assumptionText.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        let emotions = await classifyEmotions(for: trimmedText)
        
        return (trimmedText, emotions)
    }

    func classifyEmotions(for text: String) async -> EmotionAnalysis? {
        let systemPrompt = """
        You are an emotion classifier. Analyze the text and respond with ONLY a valid JSON object containing the two most dominant emotions.
        Format: {"primary": {"emotion": "Joy", "intensity": 0.9}, "secondary": {"emotion": "Surprise", "intensity": 0.4}}
        Valid emotions: [Joy, Sadness, Anger, Fear, Surprise, Neutral]. If only one real emotion is present, set the secondary emotion to "Neutral".
        """
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: text)
        ], temperature: 0, max_tokens: 150, response_format: ResponseFormat(type: "json_object"))

        return await makeStructuredRequest(with: requestBody)
    }
    
    // MARK: - Hypothesis Generation
    
    func generateHypotheses(from moments: [Moment], limit: Int = 3) async -> [Hypothesis] {
        guard moments.count >= 2 else { return [] }
        
        var hypotheses: [Hypothesis] = []
        
        // Generate pattern-based hypotheses
        if let patternHypothesis = await generatePatternHypothesis(from: moments) {
            hypotheses.append(patternHypothesis)
        }
        
        // Generate emotion-based hypotheses
        if let emotionHypothesis = await generateEmotionHypothesis(from: moments) {
            hypotheses.append(emotionHypothesis)
        }
        
        // Generate timing-based hypotheses
        if let timingHypothesis = await generateTimingHypothesis(from: moments) {
            hypotheses.append(timingHypothesis)
        }
        
        // Generate theme-based hypotheses
        if let themeHypothesis = await generateThemeHypothesis(from: moments) {
            hypotheses.append(themeHypothesis)
        }
        
        // Return shuffled subset
        return Array(hypotheses.shuffled().prefix(limit))
    }
    
    private func generatePatternHypothesis(from moments: [Moment]) async -> Hypothesis? {
        let recentMoments = Array(moments.suffix(5))
        let textsToAnalyze = recentMoments.map { $0.resonatedText ?? $0.text }.joined(separator: "\n---\n")
        
        let systemPrompt = """
        You are a pattern recognition AI. Analyze the user's recent reflections and identify a subtle behavioral or emotional pattern. Generate a gentle hypothesis as a question that starts with phrases like "It seems like..." or "I've noticed that...". The question should be insightful, non-judgmental, and invite self-reflection. Keep it under 120 characters.
        """
        
        let userPrompt = """
        Recent reflections:
        \(textsToAnalyze)
        
        Generate a pattern-based hypothesis question:
        """
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.7, max_tokens: 80, response_format: nil)
        
        guard let questionText = try? await makeChatRequest(with: requestBody) else { return nil }
        let cleanedText = questionText.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        
        return Hypothesis(id: Int.random(in: 1...10000), question_text: cleanedText)
    }
    
    private func generateEmotionHypothesis(from moments: [Moment]) async -> Hypothesis? {
        let emotionalMoments = moments.filter { moment in
            let text = moment.resonatedText ?? moment.text
            return text.localizedCaseInsensitiveContains("feel") || 
                   text.localizedCaseInsensitiveContains("emotion") ||
                   text.localizedCaseInsensitiveContains("happy") ||
                   text.localizedCaseInsensitiveContains("sad") ||
                   text.localizedCaseInsensitiveContains("anxious") ||
                   text.localizedCaseInsensitiveContains("excited")
        }
        
        guard emotionalMoments.count >= 2 else { return nil }
        
        let emotionalTexts = emotionalMoments.map { $0.resonatedText ?? $0.text }.joined(separator: "\n---\n")
        
        let systemPrompt = """
        You are an emotional intelligence AI. Analyze the user's emotionally-charged reflections and identify patterns in their emotional responses. Generate a gentle hypothesis about their emotional triggers, coping mechanisms, or emotional patterns. Frame it as a caring question starting with "It seems like..." or "I wonder if...". Keep it under 120 characters.
        """
        
        let userPrompt = """
        Emotional reflections:
        \(emotionalTexts)
        
        Generate an emotion-based hypothesis question:
        """
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.8, max_tokens: 80, response_format: nil)
        
        guard let questionText = try? await makeChatRequest(with: requestBody) else { return nil }
        let cleanedText = questionText.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        
        return Hypothesis(id: Int.random(in: 1...10000), question_text: cleanedText)
    }
    
    private func generateTimingHypothesis(from moments: [Moment]) async -> Hypothesis? {
        // Group moments by time of day
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        
        let morningMoments = moments.filter { Int(formatter.string(from: $0.timestamp))! < 12 }
        let afternoonMoments = moments.filter { let hour = Int(formatter.string(from: $0.timestamp))!; return hour >= 12 && hour < 18 }
        let eveningMoments = moments.filter { Int(formatter.string(from: $0.timestamp))! >= 18 }
        
        let timeGroups = [
            ("morning", morningMoments),
            ("afternoon", afternoonMoments), 
            ("evening", eveningMoments)
        ].filter { $0.1.count >= 2 }
        
        guard let dominantTimeGroup = timeGroups.max(by: { $0.1.count < $1.1.count }) else { return nil }
        
        let timeTexts = dominantTimeGroup.1.map { $0.resonatedText ?? $0.text }.joined(separator: "\n---\n")
        
        let systemPrompt = """
        You are a circadian rhythm and timing analysis AI. Analyze reflections from a specific time of day and identify patterns related to energy, mood, creativity, or behavior during that time. Generate a gentle hypothesis about the user's optimal times or temporal patterns. Frame it as a question starting with "It seems like..." or "I notice that...". Keep it under 120 characters.
        """
        
        let userPrompt = """
        Time period: \(dominantTimeGroup.0)
        Reflections from this time:
        \(timeTexts)
        
        Generate a timing-based hypothesis question:
        """
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.7, max_tokens: 80, response_format: nil)
        
        guard let questionText = try? await makeChatRequest(with: requestBody) else { return nil }
        let cleanedText = questionText.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        
        return Hypothesis(id: Int.random(in: 1...10000), question_text: cleanedText)
    }
    
    private func generateThemeHypothesis(from moments: [Moment]) async -> Hypothesis? {
        let allTexts = moments.map { $0.resonatedText ?? $0.text }.joined(separator: "\n---\n")
        
        let systemPrompt = """
        You are a thematic analysis AI. Analyze the user's reflections and identify recurring themes, values, or life areas they focus on (like relationships, work, creativity, health, growth, etc.). Generate a gentle hypothesis about their core values, priorities, or life themes. Frame it as a question starting with "It seems like..." or "I wonder if...". Keep it under 120 characters.
        """
        
        let userPrompt = """
        All reflections:
        \(allTexts)
        
        Generate a theme-based hypothesis question:
        """
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.6, max_tokens: 80, response_format: nil)
        
        guard let questionText = try? await makeChatRequest(with: requestBody) else { return nil }
        let cleanedText = questionText.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        
        return Hypothesis(id: Int.random(in: 1...10000), question_text: cleanedText)
    }
    
    // MARK: - Proactive Engine Functions

    func generateNotificationText(context: String, predictedState: String) async -> String? {
        let systemPrompt = "Generate a short, gentle, and insightful priming cue for a user. The cue should be an invitation to notice, not a command to act. Keep it under 150 characters and wrap it in quotes."
        let userPrompt = "Context: The user is currently \(context).\nPredicted mental state: \(predictedState)."
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.8, max_tokens: 60, response_format: nil)
        
        let notificationText = try? await makeChatRequest(with: requestBody)
        return notificationText?.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
    }
    
    func analyzeAlignment(themes: [String], values: [String], goals: [String]) async -> AlignmentAnalysis? {
        let systemPrompt = """
        You are an alignment coach. Analyze the user's recent themes against their values/goals. Identify the single most significant point of alignment AND misalignment. Your response must be a valid JSON object with the specified structure. If a connection is not found, set its value to null. Keep observations concise.
        """
        let userPrompt = """
        {"values": \(values), "goals": \(goals), "recent_themes": \(themes)}
        """
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.5, max_tokens: 400, response_format: ResponseFormat(type: "json_object"))
        
        return await makeStructuredRequest(with: requestBody)
    }

    func suggestNeuralPathway(for schemas: [CoreSchema]) async -> ThreadSuggestion? {
        let schemaDescriptions = schemas.map { "\($0.title): \($0.summary)" }.joined(separator: "\n---\n")
        let systemPrompt = """
        Analyze these core schemas. If they form a coherent narrative, respond with a JSON object: {"theme": "Journey with [theme name]", "confidence": 0.85}. The theme should be a compelling title. Confidence is 0.0-1.0. If no strong narrative exists, respond with a confidence of 0.0.
        """
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: schemaDescriptions)
        ], temperature: 0.5, max_tokens: 150, response_format: ResponseFormat(type: "json_object"))

        let suggestion: ThreadSuggestion? = await makeStructuredRequest(with: requestBody)
        return (suggestion?.confidence ?? 0) > 0.7 ? suggestion : nil
    }

    // MARK: - Workshop & Multimodal Functions

    func processWorkbenchStep(toolName: String, sessionContext: String, currentStep: String) async -> String? {
        let systemPrompt = "You are a compassionate but rigorous therapist conducting a structured analysis session with the '\(toolName)' tool. Given the session context, generate the next question or response as defined by the tool's logic. Be encouraging but stay on task."
        let userPrompt = "SESSION CONTEXT:\n\(sessionContext)\n\nCURRENT STEP INSTRUCTION: \(currentStep)"
        
        let requestBody = OpenAIRequest(model: defaultModel, messages: [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ], temperature: 0.7, max_tokens: 200, response_format: nil)
        
        return try? await makeChatRequest(with: requestBody)
    }
    
    func imageToReflectiveText(imageData: Data) async -> String? {
        let base64Image = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64Image)"
        
        let systemPrompt = "Analyze the image and generate a rich, first-person narrative text as if the user were journaling about this moment. Focus on the potential 'why' behind the image, not just the 'what'. Infer the mood and translate it into reflective words."
        let content = [
            OpenAIRequest.ImageContent(type: "text", text: systemPrompt, image_url: nil),
            OpenAIRequest.ImageContent(type: "image_url", text: nil, image_url: .init(url: dataURI))
        ]
        
        let requestBody = ["model": defaultModel, "messages": [["role": "user", "content": content]], "max_tokens": 200] as [String : Any]
        
        do {
            let data = try await makeAPIRequest(endpoint: chatEndpoint, bodyDict: requestBody)
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return response.choices.first?.message.content
        } catch {
            print("Failed to analyze image: \(error)")
            return "This image captures a moment that feels significant."
        }
    }
    
    // MARK: - Private Helpers

    public func makeChatRequest(with body: OpenAIRequest) async throws -> String? {
        let data = try await makeAPIRequest(endpoint: chatEndpoint, body: body)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return response.choices.first?.message.content
    }
    
    private func makeStructuredRequest<T: Decodable>(with body: OpenAIRequest) async -> T? {
        do {
            guard let responseText = try await makeChatRequest(with: body),
                  let data = responseText.data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to decode structured response of type \(T.self): \(error)")
            return nil
        }
    }
    
    private func makeAPIRequest<B: Encodable>(endpoint: String, body: B) async throws -> Data {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("API Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No data")")
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func makeAPIRequest(endpoint: String, bodyDict: [String: Any]) async throws -> Data {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("API Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No data")")
            throw URLError(.badServerResponse)
        }
        return data
    }
}
