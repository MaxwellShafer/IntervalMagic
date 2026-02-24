//
//  HomeView.swift
//  IntervalMagic
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IntervalSetEntity.name) private var setEntities: [IntervalSetEntity]

    var startSession: ((IntervalSet) -> Void)?

    @State private var showBuilder = false
    @State private var setToEdit: IntervalSet?
    @State private var selectedSetForStart: IntervalSet?
    @State private var selectedSetForOptions: IntervalSet?

    private var sets: [IntervalSet] {
        setEntities.map { $0.toIntervalSet() }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sets) { set in
                    IntervalSetRow(
                        set: set,
                        onTap: { selectedSetForStart = set },
                        onOptions: { selectedSetForOptions = set }
                    )
                }
            }
            .navigationTitle("Interval Magic")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showBuilder = true
                    } label: {
                        Label("Create Interval Set", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showBuilder) {
                IntervalSetBuilderView(initialSet: setToEdit)
                    .onDisappear { setToEdit = nil }
            }
            .sheet(item: $selectedSetForStart) { set in
                StartSheet(
                    set: set,
                    isPresented: Binding(
                        get: { selectedSetForStart != nil },
                        set: { if !$0 { selectedSetForStart = nil } }
                    ),
                    onStart: { effectiveSet in
                        startSession?(effectiveSet)
                        selectedSetForStart = nil
                    },
                    onStartOnWatch: { effectiveSet in
                        let store = IntervalSetStore(modelContext: modelContext)
                        let allSets = (try? store.fetchAll()) ?? []
                        WatchConnectivityManager.shared.sendIntervalSets(allSets, startSetId: effectiveSet.id)
                        selectedSetForStart = nil
                    }
                )
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedSetForOptions) { set in
                OptionsSheet(
                    set: set,
                    isPresented: Binding(
                        get: { selectedSetForOptions != nil },
                        set: { if !$0 { selectedSetForOptions = nil } }
                    ),
                    onEdit: {
                        setToEdit = set
                        selectedSetForOptions = nil
                        showBuilder = true
                    },
                    onDuplicate: { duplicated in
                        let store = IntervalSetStore(modelContext: modelContext)
                        try? store.save(duplicated)
                        selectedSetForOptions = nil
                    },
                    onDelete: {
                        deleteSet(set)
                        selectedSetForOptions = nil
                    },
                    onClose: {
                        selectedSetForOptions = nil
                    }
                )
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func deleteSet(_ set: IntervalSet) {
        let store = IntervalSetStore(modelContext: modelContext)
        try? store.delete(set)
    }
}

struct IntervalSetRow: View {
    let set: IntervalSet
    let onTap: () -> Void
    let onOptions: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(formatDuration(set.totalDurationSeconds))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Options", systemImage: "ellipsis.circle", action: onOptions)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 {
            return "\(m)m \(s)s total"
        }
        return "\(s)s total"
    }
}
