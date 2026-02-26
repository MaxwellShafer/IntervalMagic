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
    @State private var showSettings = false
    @State private var setToEdit: IntervalSet?
    @State private var selectedSetForStart: IntervalSet?
    @State private var selectedSetForOptions: IntervalSet?

    private var sets: [IntervalSet] {
        setEntities.map { $0.toIntervalSet() }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sets.isEmpty {
                    EmptyIntervalSetsView(onCreate: { showBuilder = true })
                } else {
                    List {
                        ForEach(sets) { set in
                            IntervalSetRow(
                                set: set,
                                onTap: { selectedSetForStart = set },
                                onOptions: { selectedSetForOptions = set }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Interval Magic")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    showBuilder = true
                } label: {
                    Label("Create Interval Set", systemImage: "plus.circle.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(Color(uiColor: .systemBackground))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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
                        // Send the saved sets, but override the selected set's cycle mode for this start only.
                        let patched = allSets.map { $0.id == effectiveSet.id ? effectiveSet : $0 }
                        WatchConnectivityManager.shared.sendIntervalSets(patched, startSetId: effectiveSet.id)
                        selectedSetForStart = nil
                    }
                )
                .presentationDetents([.fraction(0.55)])
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
            .sheet(isPresented: $showSettings) {
                SettingsView(isPresented: $showSettings)
            }
        }
    }

    private func deleteSet(_ set: IntervalSet) {
        let store = IntervalSetStore(modelContext: modelContext)
        try? store.delete(set)
    }
}

struct EmptyIntervalSetsView: View {
    let onCreate: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No interval sets yet", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Create your first set to get started.")
        } actions: {
            Button("Create Interval Set", action: onCreate)
                .buttonStyle(.borderedProminent)
        }
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
                Button(action: onOptions) {
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
