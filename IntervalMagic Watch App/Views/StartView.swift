//
//  StartView.swift
//  IntervalMagic Watch App
//

import SwiftUI

struct StartView: View {
    @State private var connectivity = WatchConnectivityManager.shared
    @State private var selectedSetForStart: IntervalSet?
    @State private var selectedSetForActive: IntervalSet?
    @State private var showStartConfig = false
    @State private var showActive = false

    var body: some View {
        List {
            ForEach(connectivity.intervalSets) { set in
                Button {
                    selectedSetForStart = set
                    showStartConfig = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(set.name)
                            .font(.headline)
                        Text(formatDuration(set.totalDurationSeconds))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Interval Magic")
        .sheet(isPresented: $showStartConfig) {
            if let set = selectedSetForStart {
                WatchStartConfigView(set: set) { effectiveSet in
                    selectedSetForStart = nil
                    selectedSetForActive = effectiveSet
                    showStartConfig = false
                    showActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $showActive) {
            if let set = selectedSetForActive {
                ActiveSessionView(set: set) {
                    showActive = false
                    selectedSetForActive = nil
                }
            }
        }
        .onAppear {
            handlePendingStart()
        }
        .onChange(of: connectivity.pendingStartSetId) { _, _ in
            handlePendingStart()
        }
    }

    private func handlePendingStart() {
        if let startId = connectivity.pendingStartSetId,
           let set = connectivity.intervalSets.first(where: { $0.id == startId }) {
            connectivity.clearPendingStart()
            selectedSetForStart = set
            showStartConfig = true
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

private struct WatchStartConfigView: View {
    let set: IntervalSet
    let onStart: (IntervalSet) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var useInfiniteCycles = false
    @State private var cycleCount = 1

    private var effectiveSet: IntervalSet {
        IntervalSet(
            id: set.id,
            name: set.name,
            intervals: set.intervals,
            cycleMode: useInfiniteCycles ? .infinite : .fixed(max(1, cycleCount))
        )
    }

    private var oneCycleSeconds: Int {
        self.set.singleCycleDurationSeconds
    }

    init(set: IntervalSet, onStart: @escaping (IntervalSet) -> Void) {
        self.set = set
        self.onStart = onStart
        switch set.cycleMode {
        case .fixed(let cycles):
            _useInfiniteCycles = State(initialValue: false)
            _cycleCount = State(initialValue: max(1, cycles))
        case .infinite:
            _useInfiniteCycles = State(initialValue: true)
            _cycleCount = State(initialValue: 1)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(set.name) {
                    Toggle("Infinite Cycles", isOn: $useInfiniteCycles)
                    if !useInfiniteCycles {
                        Stepper("Cycles: \(cycleCount)", value: $cycleCount, in: 1...999)
                    }
                    Text(durationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button {
                        onStart(effectiveSet)
                    } label: {
                        Label("Begin", systemImage: "play.fill")
                    }
                    .disabled(!effectiveSet.isValid)
                }
            }
            .navigationTitle("Start Session")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var durationText: String {
        if useInfiniteCycles {
            return "Total: infinite"
        }
        let total = oneCycleSeconds * max(1, cycleCount)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return String(format: "Total: %d:%02d", minutes, seconds)
        }
        return "Total: \(seconds)s"
    }
}
