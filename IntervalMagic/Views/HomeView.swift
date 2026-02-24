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
    @State private var selectedSet: IntervalSet?
    @State private var showStartSheet = false
    @State private var showOptionsSheet = false

    private var sets: [IntervalSet] {
        setEntities.map { $0.toIntervalSet() }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sets) { set in
                    IntervalSetRow(
                        set: set,
                        onTap: {
                            selectedSet = set
                            showStartSheet = true
                        },
                        onOptions: {
                            selectedSet = set
                            showOptionsSheet = true
                        }
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
            .sheet(isPresented: $showStartSheet) {
                if let set = selectedSet {
                    StartSheet(
                        set: set,
                        isPresented: $showStartSheet,
                        onStart: { effectiveSet in
                            startSession?(effectiveSet)
                            showStartSheet = false
                        },
                        onStartOnWatch: { effectiveSet in
                            let store = IntervalSetStore(modelContext: modelContext)
                            let allSets = (try? store.fetchAll()) ?? []
                            WatchConnectivityManager.shared.sendIntervalSets(allSets, startSetId: effectiveSet.id)
                            showStartSheet = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showOptionsSheet) {
                if let set = selectedSet {
                    OptionsSheet(
                        set: set,
                        isPresented: $showOptionsSheet,
                        onEdit: {
                            if let set = selectedSet {
                                setToEdit = set
                                showOptionsSheet = false
                                selectedSet = nil
                                showBuilder = true
                            }
                        },
                        onDuplicate: { duplicated in
                            let store = IntervalSetStore(modelContext: modelContext)
                            try? store.save(duplicated)
                            showOptionsSheet = false
                            selectedSet = nil
                        },
                        onDelete: {
                            deleteSet(set)
                            showOptionsSheet = false
                            selectedSet = nil
                        },
                        onClose: {
                            showOptionsSheet = false
                            selectedSet = nil
                        }
                    )
                }
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
