//
//  StartSheet.swift
//  IntervalMagic
//

import SwiftUI
import SwiftData

struct StartSheet: View {
    let set: IntervalSet
    @Binding var isPresented: Bool
    let onStart: (IntervalSet) -> Void
    let onStartOnWatch: (IntervalSet) -> Void

    @State private var cycleMode: CycleMode
    @State private var fixedCycleCount: Int
    @Environment(\.modelContext) private var modelContext

    init(set: IntervalSet, isPresented: Binding<Bool>, onStart: @escaping (IntervalSet) -> Void, onStartOnWatch: @escaping (IntervalSet) -> Void) {
        self.set = set
        _isPresented = isPresented
        self.onStart = onStart
        self.onStartOnWatch = onStartOnWatch
        switch set.cycleMode {
        case .fixed(let n):
            _cycleMode = State(initialValue: .fixed(n))
            _fixedCycleCount = State(initialValue: n)
        case .infinite:
            _cycleMode = State(initialValue: .infinite)
            _fixedCycleCount = State(initialValue: 1)
        }
    }

    private var effectiveSet: IntervalSet {
        IntervalSet(id: set.id, name: set.name, intervals: set.intervals, cycleMode: cycleMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycle") {
                    SetCycleView(cycleMode: $cycleMode, fixedCycleCount: $fixedCycleCount)
                }
                Section {
                    HStack {
                        Text("Total duration")
                        Spacer()
                        Text(formatDuration(effectiveSet.totalDurationSeconds))
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button {
                        onStart(effectiveSet)
                        isPresented = false
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!effectiveSet.isValid)

                    Button {
                        onStartOnWatch(effectiveSet)
                        isPresented = false
                    } label: {
                        Label("Start on Watch", systemImage: "applewatch")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!effectiveSet.isValid)
                }
            }
            .navigationTitle(set.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
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
