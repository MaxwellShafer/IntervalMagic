//
//  ActiveSessionView.swift
//  IntervalMagic Watch App
//

import SwiftUI
import HealthKit

struct ActiveSessionView: View {
    let set: IntervalSet
    let onDismiss: () -> Void

    @StateObject private var engine: IntervalSetEngine
    @StateObject private var muteState = WatchMuteState()
    @State private var workoutManager: WatchWorkoutManager?
    @State private var showCompletion = false

    init(set: IntervalSet, onDismiss: @escaping () -> Void) {
        self.set = set
        self.onDismiss = onDismiss
        _engine = StateObject(wrappedValue: IntervalSetEngine(set: set))
    }

    var body: some View {
        Group {
            if showCompletion {
                CompletionView(onRestart: {
                    showCompletion = false
                    engine.start()
                }, onClose: onDismiss)
            } else {
                VStack(spacing: 8) {
                    if let name = engine.currentInterval?.name {
                        Text(name)
                            .font(.headline)
                    }
                    Text(formatTime(engine.timeRemaining))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    if let total = engine.totalCycles {
                        Text("Cycle \(engine.currentCycle)/\(total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Cycle \(engine.currentCycle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button {
                            if engine.isPaused {
                                engine.resume()
                            } else {
                                engine.pause()
                            }
                        } label: {
                            Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                        }
                        if engine.isPaused {
                            Button {
                                engine.stop()
                                showCompletion = true
                                workoutManager?.endWorkout()
                            } label: {
                                Image(systemName: "stop.fill")
                            }
                        }
                        Toggle("Mute", isOn: Binding(
                            get: { muteState.hapticsMuted },
                            set: { muteState.hapticsMuted = $0 }
                        ))
                        .labelsHidden()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            engine.onCue = { [muteState] cueType in
                if !muteState.hapticsMuted {
                    WatchHapticCueService.shared.play(cueType: cueType)
                }
                WatchSoundCueService.shared.play(cueType: cueType)
            }
            workoutManager = WatchWorkoutManager()
            workoutManager?.startWorkout()
            engine.start()
        }
        .onChange(of: engine.isCompleted) { _, completed in
            if completed {
                workoutManager?.endWorkout()
                WatchHapticCueService.shared.play(style: .double)
                showCompletion = true
            }
        }
        .onDisappear {
            engine.stop()
            workoutManager?.endWorkout()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private final class WatchMuteState: ObservableObject {
    @Published var hapticsMuted = false
}
