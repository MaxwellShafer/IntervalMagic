//
//  StartView.swift
//  IntervalMagic Watch App
//

import SwiftUI

struct StartView: View {
    @State private var connectivity = WatchConnectivityManager.shared
    @State private var selectedSet: IntervalSet?
    @State private var showActive = false

    var body: some View {
        List {
            ForEach(connectivity.intervalSets) { set in
                Button {
                    selectedSet = set
                    showActive = true
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
        .fullScreenCover(isPresented: $showActive) {
            if let set = selectedSet {
                ActiveSessionView(set: set) {
                    showActive = false
                    selectedSet = nil
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
            selectedSet = set
            showActive = true
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
