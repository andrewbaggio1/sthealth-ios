import SwiftUI
import SwiftData

struct CompassView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var values: [CompassValue]
    @Query private var goals: [CompassGoal]
    
    @State private var selectedTab = 0
    @State private var showingAddSheet = false
    @State private var editingValue: CompassValue?
    @State private var editingGoal: CompassGoal?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Segmented Control
                HStack(spacing: 0) {
                    ForEach(0..<2) { index in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text(index == 0 ? "Values" : "Goals")
                                    .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                                    .foregroundColor(selectedTab == index ? .primaryAccent : .secondaryText)
                                
                                Rectangle()
                                    .fill(selectedTab == index ? Color.primaryAccent : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            // Values Tab
                            if values.isEmpty {
                                emptyStateView(
                                    icon: "heart.circle.fill",
                                    title: "No Values Yet",
                                    message: "Add your core values to help guide your reflections and insights"
                                )
                            } else {
                                ForEach(values.sorted(by: { $0.createdAt > $1.createdAt })) { value in
                                    ValueCard(value: value, onEdit: {
                                        editingValue = value
                                    }, onDelete: {
                                        deleteValue(value)
                                    })
                                }
                            }
                        } else {
                            // Goals Tab
                            if goals.isEmpty {
                                emptyStateView(
                                    icon: "target",
                                    title: "No Goals Yet",
                                    message: "Set goals to track your progress and maintain focus"
                                )
                            } else {
                                ForEach(goals.sorted(by: { $0.createdAt > $1.createdAt })) { goal in
                                    GoalCard(goal: goal, onEdit: {
                                        editingGoal = goal
                                    }, onDelete: {
                                        deleteGoal(goal)
                                    })
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Compass")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primaryAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCompassItemView(selectedTab: selectedTab)
        }
        .sheet(item: $editingValue) { value in
            EditValueView(value: value)
        }
        .sheet(item: $editingGoal) { goal in
            EditGoalView(goal: goal)
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.tertiaryText)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add \(selectedTab == 0 ? "Value" : "Goal")")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.primaryAccent)
                .cornerRadius(25)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
    }
    
    private func deleteValue(_ value: CompassValue) {
        withAnimation {
            modelContext.delete(value)
        }
    }
    
    private func deleteGoal(_ goal: CompassGoal) {
        withAnimation {
            modelContext.delete(goal)
        }
    }
}

// MARK: - Value Card
struct ValueCard: View {
    let value: CompassValue
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primaryAccent)
                
                Text(value.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.tertiaryText)
                }
            }
            
            if let description = value.userDescription, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .lineLimit(3)
            }
            
            HStack {
                Text("Added \(value.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .alert("Delete Value", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this value? This action cannot be undone.")
        }
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let goal: CompassGoal
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.isActive ? "target" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(goal.isActive ? .primaryAccent : .green)
                
                Text(goal.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .strikethrough(!goal.isActive, color: .tertiaryText)
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.tertiaryText)
                }
            }
            
            if let description = goal.userDescription, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .lineLimit(3)
            }
            
            HStack {
                if goal.isActive {
                    Label("Active", systemImage: "circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Text("Added \(goal.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(16)
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .alert("Delete Goal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
    }
}

// MARK: - Add Compass Item View
struct AddCompassItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedTab: Int
    
    @State private var name = ""
    @State private var description = ""
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedTab == 0 ? "Add a Core Value" : "Set a Goal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)
                    
                    Text(selectedTab == 0 ? 
                         "Values guide your decisions and reflections" : 
                         "Goals help you track progress and maintain focus")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedTab == 0 ? "Value Name" : "Goal Title")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextField(
                            selectedTab == 0 ? "e.g., Authenticity, Growth, Connection" : "e.g., Practice meditation daily",
                            text: $name
                        )
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color.secondaryBackground)
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextEditor(text: $description)
                            .font(.system(size: 16))
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    save()
                } label: {
                    Text("Add \(selectedTab == 0 ? "Value" : "Goal")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.primaryAccent : Color.tertiaryText)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if selectedTab == 0 {
            let value = CompassValue(
                name: trimmedName,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            modelContext.insert(value)
        } else {
            let goal = CompassGoal(
                title: trimmedName,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            modelContext.insert(goal)
        }
        
        dismiss()
    }
}

// MARK: - Edit Value View
struct EditValueView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let value: CompassValue
    
    @State private var name: String
    @State private var description: String
    
    init(value: CompassValue) {
        self.value = value
        self._name = State(initialValue: value.name)
        self._description = State(initialValue: value.userDescription ?? "")
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit Value")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Value Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextField("e.g., Authenticity, Growth, Connection", text: $name)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextEditor(text: $description)
                            .font(.system(size: 16))
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    save()
                } label: {
                    Text("Save Changes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.primaryAccent : Color.tertiaryText)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        value.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        value.userDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        
        dismiss()
    }
}

// MARK: - Edit Goal View
struct EditGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let goal: CompassGoal
    
    @State private var title: String
    @State private var description: String
    @State private var isActive: Bool
    
    init(goal: CompassGoal) {
        self.goal = goal
        self._title = State(initialValue: goal.title)
        self._description = State(initialValue: goal.userDescription ?? "")
        self._isActive = State(initialValue: goal.isActive)
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit Goal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Title")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextField("e.g., Practice meditation daily", text: $title)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextEditor(text: $description)
                            .font(.system(size: 16))
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Text("Status")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isActive)
                            .labelsHidden()
                            .tint(.primaryAccent)
                        
                        Text(isActive ? "Active" : "Completed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isActive ? .primaryAccent : .secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background(Color.secondaryBackground)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    save()
                } label: {
                    Text("Save Changes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.primaryAccent : Color.tertiaryText)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        goal.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.userDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        goal.isActive = isActive
        
        dismiss()
    }
}

#Preview {
    CompassView()
}