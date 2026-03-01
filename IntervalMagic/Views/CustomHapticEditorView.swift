//
//  CustomHapticEditorView.swift
//  IntervalMagic
//

import SwiftUI

private struct IdentifiableStep: Identifiable {
    let id = UUID()
    var step: CustomHapticStep
}

struct CustomHapticEditorView: View {
    let definition: CustomHapticDefinition
    let onSave: (CustomHapticDefinition) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var stepRows: [IdentifiableStep] = []
    @State private var showAddStepChoice = false
    @State private var stepToEdit: IdentifiableStep?
    @State private var editingIndex: Int?
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Custom Haptic", text: $name)
                        .focused($nameFocused)
                }

                Section("Steps") {
                    ForEach(stepRows.indices, id: \.self) { index in
                        let row = stepRows[index]
                        Button {
                            editingIndex = index
                            stepToEdit = row
                        } label: {
                            HStack {
                                stepLabel(row.step)
                                Spacer()
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onMove(perform: moveSteps)
                    .onDelete(perform: deleteSteps)

                    Button {
                        showAddStepChoice = true
                    } label: {
                        Label("Add Step", systemImage: "plus.circle")
                    }
                }

                Section {
                    Button {
                        let steps = stepRows.map(\.step)
                        HapticCueService.shared.playSteps(steps)
                    } label: {
                        Label("Preview", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(stepRows.isEmpty)
                } footer: {
                    Text("Feel the current haptic pattern before saving.")
                }
            }
            .navigationTitle(definition.name?.isEmpty == false ? "Edit Haptic" : "New Haptic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                name = definition.displayName
                let steps = definition.steps.isEmpty && !definition.pattern.isEmpty
                    ? CustomCuesStore.steps(fromLegacyPattern: definition.pattern)
                    : definition.steps
                stepRows = steps.map { IdentifiableStep(step: $0) }
            }
            .confirmationDialog("Add Step", isPresented: $showAddStepChoice) {
                Button("Haptic") {
                    addHapticStep()
                }
                Button("Delay") {
                    addDelayStep()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose the type of step to add.")
            }
            .sheet(item: $stepToEdit) { row in
                StepEditorSheet(
                    step: row.step,
                    onSave: { newStep in
                        if let idx = editingIndex, idx < stepRows.count {
                            stepRows[idx] = IdentifiableStep(step: newStep)
                        }
                        stepToEdit = nil
                        editingIndex = nil
                    },
                    onCancel: {
                        stepToEdit = nil
                        editingIndex = nil
                    }
                )
            }
        }
    }

    private func stepLabel(_ step: CustomHapticStep) -> some View {
        Group {
            switch step {
            case .delay(let seconds):
                Text("Delay \(formatDelay(seconds))")
            case .haptic(let style, let intensity):
                Text("\(style.displayName), \(Int(round(intensity * 100)))%")
            }
        }
    }

    private func formatDelay(_ seconds: Double) -> String {
        if seconds < 1 {
            return String(format: "%.2f s", seconds)
        }
        return String(format: "%.1f s", seconds)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let steps = stepRows.map(\.step)
        let updated = CustomHapticDefinition(
            id: definition.id,
            name: trimmed,
            pattern: definition.pattern,
            steps: steps
        )
        onSave(updated)
    }

    private func moveSteps(from source: IndexSet, to destination: Int) {
        stepRows.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteSteps(at offsets: IndexSet) {
        stepRows.remove(atOffsets: offsets)
    }

    private func addHapticStep() {
        stepRows.append(IdentifiableStep(step: .haptic(style: .medium, intensity: 1.0)))
    }

    private func addDelayStep() {
        stepRows.append(IdentifiableStep(step: .delay(seconds: 0.5)))
    }
}

// MARK: - Step editor sheet (add/edit single step)

private struct StepEditorSheet: View {
    let step: CustomHapticStep
    let onSave: (CustomHapticStep) -> Void
    let onCancel: () -> Void

    @State private var stepStyle: ImpactHapticStyle = .medium
    @State private var intensity: Double = 1.0
    @State private var delaySeconds: Double = 0.5
    @State private var isDelay: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $isDelay) {
                    Text("Haptic").tag(false)
                    Text("Delay").tag(true)
                }
                .pickerStyle(.segmented)

                if isDelay {
                    Section("Duration") {
                        HStack {
                            Text("Seconds")
                            Slider(value: $delaySeconds, in: 0.1...2.0, step: 0.1)
                            Text(String(format: "%.1f", delaySeconds))
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                } else {
                    Section("Haptic") {
                        Picker("Style", selection: $stepStyle) {
                            ForEach(ImpactHapticStyle.allCases, id: \.self) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        HStack {
                            Text("Intensity")
                            Slider(value: $intensity, in: 0...1, step: 0.05)
                            Text("\(Int(round(intensity * 100)))%")
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
            .navigationTitle("Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if isDelay {
                            onSave(.delay(seconds: delaySeconds))
                        } else {
                            onSave(.haptic(style: stepStyle, intensity: intensity))
                        }
                    }
                }
            }
            .onAppear {
                switch step {
                case .delay(let seconds):
                    isDelay = true
                    delaySeconds = seconds
                case .haptic(let style, let int):
                    isDelay = false
                    stepStyle = style
                    intensity = int
                }
            }
        }
    }
}
