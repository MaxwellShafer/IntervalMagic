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
                WatchStartConfigView(set: set) {
                    selectedSetForStart = nil
                    selectedSetForActive = set
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
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var connectivity = WatchConnectivityManager.shared
    @State private var didStart = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        performStart()
                    } label: {
                        Label("Begin", systemImage: "play.fill")
                    }
                    .disabled(!set.isValid)
                }
                Section(set.name) {
                    Text(cycleText)
                    Text("Total: \(formatDuration(set.totalDurationSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .onAppear {
                if connectivity.phoneRequestedBegin {
                    performStart()
                }
            }
            .onChange(of: connectivity.phoneRequestedBegin) { _, requested in
                if requested {
                    performStart()
                }
            }
        }
    }

    private func performStart() {
        guard !didStart else { return }
        didStart = true
        connectivity.clearPhoneRequestedBegin()
        connectivity.sendWatchSessionStarted()
        onStart()
    }

    private var cycleText: String {
        switch set.cycleMode {
        case .fixed(let count):
            return "Cycles: \(count)"
        case .infinite:
            return "Cycles: Infinite"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainder)
        }
        return "\(remainder)s"
    }
}
