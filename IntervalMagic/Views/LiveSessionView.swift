//
//  LiveSessionView.swift
//  IntervalMagic
//

import SwiftUI
import Combine

struct LiveSessionView: View {
    let set: IntervalSet
    var restoreState: SessionState?
    let onDismiss: () -> Void

    @StateObject private var engine: IntervalSetEngine
    @StateObject private var muteState = MuteState()
    @State private var showStopConfirmation = false

    init(set: IntervalSet, restoreState: SessionState? = nil, onDismiss: @escaping () -> Void) {
        self.set = set
        self.restoreState = restoreState
        self.onDismiss = onDismiss
        _engine = StateObject(wrappedValue: IntervalSetEngine(set: set))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if engine.isCompleted {
                    Text("Done")
                        .font(.largeTitle)
                    Button("Close", action: onDismiss)
                } else {
                    if let total = engine.totalCycles {
                        Text("Cycle \(engine.currentCycle) of \(total)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Cycle \(engine.currentCycle)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    if let name = engine.currentInterval?.name {
                        Text("Interval: \(name)")
                            .font(.title2)
                    }

                    Text(formatTime(engine.timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))

                    if let next = engine.nextCueStyle {
                        Text("Next cue: \(next)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 20) {
                        Button {
                            if engine.isPaused {
                                engine.resume()
                            } else {
                                engine.pause()
                            }
                        } label: {
                            Label(engine.isPaused ? "Resume" : "Pause", systemImage: engine.isPaused ? "play.fill" : "pause.fill")
                        }

                        Toggle("Mute haptics", isOn: Binding(
                            get: { muteState.hapticsMuted },
                            set: { muteState.hapticsMuted = $0 }
                        ))
                            .labelsHidden()
                        Image(systemName: muteState.hapticsMuted ? "speaker.slash" : "hand.raised")
                    }
                }
            }
            .padding()
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showStopConfirmation = true
                    }
                }
            }
            .confirmationDialog("Stop workout?", isPresented: $showStopConfirmation) {
                Button("Stop", role: .destructive) {
                    engine.stop()
                    SessionPersistence.clear()
                    onDismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your progress will not be saved.")
            }
            .onAppear {
                engine.onCue = { [muteState] cueType in
                    if !muteState.hapticsMuted {
                        HapticCueService.shared.play(cueType: cueType)
                    }
                    SoundCueService.shared.play(cueType: cueType)
                }
                if let state = restoreState {
                    engine.restore(
                        intervalIndex: state.intervalIndex,
                        cycle: state.cycle,
                        timeRemaining: state.timeRemaining,
                        isPaused: state.isPaused
                    )
                    if !state.isPaused {
                        engine.resume()
                    }
                } else {
                    engine.start()
                }
            }
            .onDisappear {
                if !engine.isCompleted && engine.isRunning {
                    let snap = engine.stateSnapshot
                    SessionPersistence.save(SessionState(
                        setId: set.id,
                        intervalIndex: snap.intervalIndex,
                        cycle: snap.cycle,
                        timeRemaining: snap.timeRemaining,
                        isPaused: snap.isPaused
                    ))
                }
                engine.stop()
            }
            .onChange(of: engine.isPaused) { _, isPaused in
                let snap = engine.stateSnapshot
                SessionPersistence.save(SessionState(
                    setId: set.id,
                    intervalIndex: snap.intervalIndex,
                    cycle: snap.cycle,
                    timeRemaining: snap.timeRemaining,
                    isPaused: isPaused
                ))
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private final class MuteState: ObservableObject {
    @Published var hapticsMuted = false
}
