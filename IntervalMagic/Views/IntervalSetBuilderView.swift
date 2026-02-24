//
//  IntervalSetBuilderView.swift
//  IntervalMagic
//

import SwiftUI
import SwiftData

struct IntervalSetBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: IntervalSetBuilderViewModel
    @State private var showAddInterval = false
    @State private var editingIndex: Int?
    @State private var showIntervalOptions = false
    @State private var optionsIndex: Int?
    private struct EditIndex: Identifiable { let id: Int }

    init(initialSet: IntervalSet? = nil) {
        let vm: IntervalSetBuilderViewModel
        if let s = initialSet {
            vm = IntervalSetBuilderViewModel(
                setId: s.id,
                setName: s.name,
                intervals: s.intervals,
                cycleMode: s.cycleMode
            )
        } else {
            vm = IntervalSetBuilderViewModel()
        }
        _viewModel = State(initialValue: vm)
    }

    private var fixedCycleCount: Int {
        get {
            if case .fixed(let n) = viewModel.cycleMode { return n }
            return 1
        }
        set {
            viewModel.cycleMode = .fixed(max(1, newValue))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Set name") {
                    TextField("Interval set name", text: $viewModel.setName)
                }

                Section {
                    Button {
                        showAddInterval = true
                    } label: {
                        Label("Add Interval", systemImage: "plus.circle.fill")
                    }

                    ForEach(Array(viewModel.intervals.enumerated()), id: \.element.id) { index, interval in
                        IntervalRowBuilder(
                            interval: interval,
                            onEdit: { editingIndex = index },
                            onDuplicate: { viewModel.duplicateInterval(at: index) },
                            onDelete: { viewModel.deleteInterval(at: index) }
                        )
                    }
                    .onMove(perform: viewModel.moveInterval(from:to:))
                } header: {
                    Text("Intervals")
                }

                Section("Cycle") {
                    SetCycleView(cycleMode: $viewModel.cycleMode, fixedCycleCount: Binding(
                        get: { fixedCycleCount },
                        set: { newValue in viewModel.cycleMode = .fixed(max(1, newValue)) }
                    ))
                }

                Section {
                    HStack {
                        Text("Total duration")
                        Spacer()
                        Text(formatDuration(viewModel.totalDurationSeconds))
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = viewModel.validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Interval Set Builder")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showAddInterval) {
                AddIntervalSheet(isPresented: $showAddInterval, suggestedName: "Interval \(viewModel.intervals.count + 1)") { interval in
                    viewModel.addInterval(interval)
                }
            }
            .sheet(item: Binding(
                get: { editingIndex.flatMap { EditIndex(id: $0) } },
                set: { editingIndex = $0?.id }
            )) { editIndex in
                let idx = editIndex.id
                EditIntervalSheet(
                    isPresented: Binding(
                        get: { true },
                        set: { if !$0 { editingIndex = nil } }
                    ),
                    interval: viewModel.intervals[idx],
                    suggestedName: "Interval \(idx + 1)",
                    onSave: { updated in
                        viewModel.updateInterval(at: idx, with: updated)
                        editingIndex = nil
                    }
                )
            }
        }
    }

    private func save() {
        guard viewModel.validate() else { return }
        let set = viewModel.set
        let store = IntervalSetStore(modelContext: modelContext)
        do {
            try store.save(set)
            dismiss()
        } catch {
            viewModel.validationError = error.localizedDescription
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 {
            return String(format: "%d:%02d", m, s)
        }
        return "\(s)s"
    }
}

struct EditIntervalSheet: View {
    @Binding var isPresented: Bool
    let interval: Interval
    var suggestedName: String?
    let onSave: (Interval) -> Void

    @State private var name: String
    @State private var durationSeconds: Int
    @State private var cueType: CueType

    init(isPresented: Binding<Bool>, interval: Interval, suggestedName: String? = nil, onSave: @escaping (Interval) -> Void) {
        _isPresented = isPresented
        self.interval = interval
        self.suggestedName = suggestedName
        self.onSave = onSave
        _name = State(initialValue: interval.name)
        _durationSeconds = State(initialValue: interval.durationSeconds)
        _cueType = State(initialValue: interval.cueType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Interval") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Duration (seconds)")
                        Spacer()
                        TextField("", value: $durationSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Stepper("", value: $durationSeconds, in: 1...3600)
                            .labelsHidden()
                    }
                }
                Section {
                    CueSelectionView(cueType: $cueType)
                }
            }
            .navigationTitle("Edit Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let displayName = name.trimmingCharacters(in: .whitespaces).isEmpty
                            ? (suggestedName ?? "Interval")
                            : name
                        onSave(Interval(id: interval.id, name: displayName, durationSeconds: max(1, durationSeconds), cueType: cueType))
                        isPresented = false
                    }
                    .disabled(durationSeconds < 1)
                }
            }
        }
    }
}
