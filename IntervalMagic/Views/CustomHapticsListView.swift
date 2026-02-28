//
//  CustomHapticsListView.swift
//  IntervalMagic
//

import SwiftUI

struct CustomHapticsListView: View {
    private let store = CustomCuesStore.shared
    @State private var editorDefinition: CustomHapticDefinition?
    @State private var isPresentingNewEditor = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.customHaptics.isEmpty {
                    ContentUnavailableView {
                        Label("No Custom Haptics", systemImage: "waveform.path")
                    } description: {
                        Text("Create a custom haptic pattern to use as an interval cue.")
                    }
                } else {
                    List {
                        ForEach(store.customHaptics) { def in
                            Button {
                                editorDefinition = def
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(def.displayName)
                                            .font(.body)
                                        Text(stepCountSummary(def))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .deleteDisabled(false)
                        }
                        .onDelete(perform: deleteHaptics)
                    }
                }
            }
            .navigationTitle("Custom Haptics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorDefinition = CustomHapticDefinition(name: "Custom Haptic", pattern: [], steps: [])
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editorDefinition) { def in
                CustomHapticEditorView(
                    definition: def,
                    onSave: { updated in
                        store.addOrUpdate(updated)
                        editorDefinition = nil
                    },
                    onCancel: {
                        editorDefinition = nil
                    }
                )
            }
        }
    }

    private func stepCountSummary(_ def: CustomHapticDefinition) -> String {
        let steps = def.steps.isEmpty ? CustomCuesStore.steps(fromLegacyPattern: def.pattern) : def.steps
        let count = steps.count
        return count == 1 ? "1 step" : "\(count) steps"
    }

    private func deleteHaptics(at offsets: IndexSet) {
        let list = store.customHaptics
        let idsToDelete = offsets.compactMap { index -> UUID? in
            guard index < list.count else { return nil }
            return list[index].id
        }
        for id in idsToDelete {
            store.deleteCustomHaptic(id: id)
        }
    }
}
