//
//  CognitiveAtlasView.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/16/25.
//

import SwiftUI
import SwiftData

// MARK: - Main Cognitive Atlas View
struct CognitiveAtlasView: View {
    @Query(sort: \CoreSchema.creationDate, order: .reverse) private var coreSchemas: [CoreSchema]
    @Query private var compassValues: [CompassValue]
    @Query private var compassGoals: [CompassGoal]
    @Query(sort: \NeuralPathway.createdAt) private var neuralPathways: [NeuralPathway]
    
    @State private var selectedSchemaID: UUID?
    @State private var canvasTransform = CanvasTransform()
    
    @State private var showQuadrantLabels = true
    @State private var showHelp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Canvas { context, size in
                    canvasTransform.size = size
                    context.addFilter(.shadow(color: .cyan.opacity(0.3), radius: 10))
                    
                    context.translateBy(x: canvasTransform.offset.width, y: canvasTransform.offset.height)
                    context.scaleBy(x: canvasTransform.scale, y: canvasTransform.scale)
                    
                    drawGrid(in: &context, size: size)
                    if showQuadrantLabels { drawQuadrantLabels(in: &context) }
                    drawNeuralPathways(in: &context)
                }
                .gesture(canvasTransform.dragGesture)
                .gesture(canvasTransform.magnificationGesture)
                
                nodeOverlay
                
                controlsOverlay
                
                if coreSchemas.isEmpty && compassValues.isEmpty && compassGoals.isEmpty {
                    emptyStateView
                }
            }
            .navigationTitle("Cognitive Atlas").navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .sheet(item: Binding(get: { selectedCoreSchema }, set: { _ in selectedSchemaID = nil })) { schema in
                CoreSchemaDetailView(coreSchema: schema)
            }
        }
    }
    
    // MARK: View Components
    
    private var nodeOverlay: some View {
        GeometryReader { geometry in
            let canvasCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                ForEach(coreSchemas) { schema in
                    CoreSchemaNode(
                        schema: schema,
                        isSelected: selectedSchemaID == schema.id
                    )
                    .position(canvasTransform.transform(point: CGPoint(x: schema.positionX, y: schema.positionY), in: canvasCenter))
                    .onTapGesture {
                        withAnimation(AppAnimation.standard) {
                            selectedSchemaID = (selectedSchemaID == schema.id) ? nil : schema.id
                        }
                    }
                }
            }
        }
    }
    
    private var controlsOverlay: some View {
        VStack {
            HStack {
                Button { showHelp = true } label: { Image(systemName: "questionmark.circle").font(.title2) }
                Spacer()
                Button { withAnimation { canvasTransform.reset() } } label: { Image(systemName: "arrow.counterclockwise.circle").font(.title2) }
                Button { withAnimation { showQuadrantLabels.toggle() } } label: { Image(systemName: showQuadrantLabels ? "tag.slash" : "tag").font(.title2) }
            }
            .padding().foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .sheet(isPresented: $showHelp) { CognitiveAtlasHelpView() }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "circle.grid.hex.fill").font(.system(size: 60)).foregroundColor(.white.opacity(0.3))
            Text("Your Cognitive Atlas is empty").font(.body).foregroundColor(.white.opacity(0.6))
            Text("Add reflections and work through insights to build your mental map.").font(.caption).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }
    
    private var selectedCoreSchema: CoreSchema? {
        coreSchemas.first { $0.id == selectedSchemaID }
    }
    
    // MARK: Canvas Drawing
    
    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        // Function to draw a background grid would go here
    }
    
    private func drawQuadrantLabels(in context: inout GraphicsContext) {
        let quadrants = [("Work", CGPoint(x: -250, y: -250)), ("Relationships", CGPoint(x: 250, y: -250)),
                         ("Health", CGPoint(x: -250, y: 250)), ("Self", CGPoint(x: 250, y: 250))]
        
        for (label, position) in quadrants {
            context.draw(Text(label).font(.system(size: 24, weight: .light)).foregroundColor(.white.opacity(0.2)), at: position)
        }
    }
    
    private func drawNeuralPathways(in context: inout GraphicsContext) {
        for pathway in neuralPathways {
            guard let schemasInPathway = pathway.coreSchemas, schemasInPathway.count >= 2 else { continue }
            
            var path = Path()
            let sortedSchemas = schemasInPathway.sorted { $0.creationDate < $1.creationDate }
            path.move(to: CGPoint(x: sortedSchemas[0].positionX, y: sortedSchemas[0].positionY))
            
            for i in 1..<sortedSchemas.count {
                let p1 = CGPoint(x: sortedSchemas[i-1].positionX, y: sortedSchemas[i-1].positionY)
                let p2 = CGPoint(x: sortedSchemas[i].positionX, y: sortedSchemas[i].positionY)
                let midPoint = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                path.addQuadCurve(to: p2, control: midPoint)
            }
            
            let gradient = Gradient(colors: [.cyan.opacity(0.7), .purple.opacity(0.7)])
            context.stroke(path, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 500, y: 500)), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
        }
    }
}

// MARK: - Node & Detail Views
private struct CoreSchemaNode: View {
    let schema: CoreSchema
    let isSelected: Bool
    
    private var nodeColor: Color {
        switch schema.status {
        case .active: return .red
        case .dormant: return .orange
        case .resolved: return .green
        case .transforming: return .cyan
        }
    }
    
    private var nodeSize: CGFloat { 60 + ((schema.centralityScore ?? 0.5) * 40) }
    
    var body: some View {
        ZStack {
            Circle().fill(nodeColor.opacity(0.3))
            Circle().stroke(nodeColor, lineWidth: isSelected ? 4 : 2)
            Image(systemName: icon(for: schema.quadrant ?? "Self"))
                .font(.system(size: nodeSize * 0.4)).foregroundColor(.white)
        }
        .frame(width: nodeSize, height: nodeSize)
        .overlay(Text(schema.title).font(.caption2).foregroundColor(.white).offset(y: nodeSize / 2 + 10))
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .shadow(color: nodeColor, radius: isSelected ? 15 : 8)
        .animation(AppAnimation.standard, value: isSelected)
    }
    
    private func icon(for quadrant: String) -> String {
        switch quadrant {
        case "Work": "briefcase.fill"
        case "Relationships": "person.2.fill"
        case "Health": "heart.fill"
        default: "person.fill"
        }
    }
}

private struct CoreSchemaDetailView: View {
    let coreSchema: CoreSchema
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack { Text(coreSchema.summary) }.padding()
            .navigationTitle(coreSchema.title)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct CognitiveAtlasHelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Core Schemas") {
                    Label("Schemas are your core themes and insights, shown as nodes.", systemImage: "circle.grid.hex.fill")
                    Label("Their size represents importance; their color shows status.", systemImage: "paintpalette")
                }
                Section("Connections") {
                    Label("Neural Pathways connect related schemas into a narrative.", systemImage: "line.3.crossed.swirl.circle.fill")
                }
            }
            .navigationTitle("Cognitive Atlas Guide")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Canvas Transform Helper
@Observable
class CanvasTransform {
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var size: CGSize = .zero

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                self.offset = CGSize(width: value.translation.width + self.offset.width,
                                     height: value.translation.height + self.offset.height)
            }
    }

    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                self.scale = max(0.4, min(2.5, value))
            }
    }
    
    func transform(point: CGPoint, in center: CGPoint) -> CGPoint {
        let transformedX = center.x + (point.x * scale) + offset.width
        let transformedY = center.y + (point.y * scale) + offset.height
        return CGPoint(x: transformedX, y: transformedY)
    }

    func reset() {
        self.offset = .zero
        self.scale = 1.0
    }
}
