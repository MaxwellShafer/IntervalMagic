//
//  ActiveSessionView.swift
//  IntervalMagic Watch App
//

import SwiftUI
import HealthKit
import Combine

struct ActiveSessionView: View {
    let set: IntervalSet
    let onDismiss: () -> Void

    @StateObject private var engine: IntervalSetEngine
    @StateObject private var muteState = WatchMuteState()
    @State private var workoutManager: WatchWorkoutManager?
    @State private var showCompletion = false
    @State private var userStopped = false

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
                    VStack(spacing: 8) {
                        if engine.isPaused {
                            HStack {
                                Button {
                                    engine.resume()
                                } label: {
                                    Image(systemName: "play.fill")
                                }

                                Button(role: .destructive) {
                                    stopAndDismiss()
                                } label: {
                                    Image(systemName: "stop.fill")
                                }
                            }
                        } else {
                            Button {
                                engine.pause()
                            } label: {
                                Image(systemName: "pause.fill")
                            }
                        }
                        Toggle("Mute", isOn: Binding(
                            get: { muteState.hapticsMuted && muteState.soundsMuted },
                            set: {
                                muteState.hapticsMuted = $0
                                muteState.soundsMuted = $0
                            }
                        ))
                        .labelsHidden()
                        if let nextInterval = engine.nextInterval {
                            VStack(spacing: 2) {
                                Text("Next")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(nextInterval.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                if let cue = engine.cueStyleString(for: nextInterval.cueType) {
                                    Text(cue)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            userStopped = false
            engine.onCue = { [muteState] cueType in
                if !muteState.hapticsMuted {
                    WatchHapticCueService.shared.play(cueType: cueType)
                }
                if !muteState.soundsMuted {
                    WatchSoundCueService.shared.play(cueType: cueType)
                }
            }
            workoutManager = WatchWorkoutManager()
            workoutManager?.startWorkout()
            engine.start()
        }
        .onChange(of: engine.isCompleted) { _, completed in
            if completed && !userStopped {
                workoutManager?.endWorkout()
                WatchHapticCueService.shared.play(style: HapticStyle.double)
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

    private func stopAndDismiss() {
        userStopped = true
        engine.stop()
        workoutManager?.endWorkout()
        onDismiss()
    }
}

private final class WatchMuteState: ObservableObject {
    @Published var hapticsMuted = false
    @Published var soundsMuted = false
}
