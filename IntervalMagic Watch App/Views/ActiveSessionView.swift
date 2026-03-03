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
    @State private var connectivity = WatchConnectivityManager.shared
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
                    VStack(spacing: 8) {
                        if engine.isPaused {
                            HStack {
                                Button {
                                    engine.resume()
                                    sendCurrentSnapshot()
                                } label: {
                                    Image(systemName: "play.fill")
                                }

                                Button(role: .destructive) {
                                    stopAndDismiss(sendStopMessage: true)
                                } label: {
                                    Image(systemName: "stop.fill")
                                }
                            }
                        } else {
                            Button {
                                engine.pause()
                                sendCurrentSnapshot()
                            } label: {
                                Image(systemName: "pause.fill")
                            }
                        }
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
        .preferredColorScheme(connectivity.appSettings.useLightMode ? .light : nil)
        .onAppear {
            engine.onCue = { [muteState] cueType in
                if !muteState.hapticsMuted {
                    WatchHapticCueService.shared.play(cueType: cueType)
                }
                if !muteState.soundsMuted {
                    WatchSoundCueService.shared.play(cueType: cueType)
                }
            }
            muteState.hapticsMuted = connectivity.receivedMuteUpdate.hapticsMuted
            muteState.soundsMuted = connectivity.receivedMuteUpdate.soundsMuted
            workoutManager = WatchWorkoutManager()
            workoutManager?.startWorkout()
            engine.start()
            sendCurrentSnapshot(started: true)
        }
        .onChange(of: connectivity.sessionControlEvent) { _, _ in
            applyRemoteControl()
        }
        .onChange(of: connectivity.receivedMuteUpdate) { _, update in
            muteState.hapticsMuted = update.hapticsMuted
            muteState.soundsMuted = update.soundsMuted
        }
        .onChange(of: engine.timeRemaining) { _, _ in sendCurrentSnapshot() }
        .onChange(of: engine.currentIntervalIndex) { _, _ in sendCurrentSnapshot() }
        .onChange(of: engine.currentCycle) { _, _ in sendCurrentSnapshot() }
        .onChange(of: engine.isPaused) { _, _ in sendCurrentSnapshot() }
        .onChange(of: engine.isCompleted) { _, completed in
            if completed {
                workoutManager?.endWorkout()
                WatchHapticCueService.shared.play(style: HapticStyle.double)
                connectivity.sendSessionCompleted()
                showCompletion = true
            }
        }
        .onDisappear {
            if !engine.isCompleted && engine.isRunning {
                connectivity.sendSessionStopped()
            }
            engine.stop()
            workoutManager?.endWorkout()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func currentSnapshot() -> SessionSnapshot {
        let state = engine.stateSnapshot
        return SessionSnapshot(
            setId: set.id,
            intervalIndex: state.intervalIndex,
            cycle: state.cycle,
            timeRemaining: state.timeRemaining,
            isPaused: state.isPaused,
            isCompleted: engine.isCompleted
        )
    }

    private func sendCurrentSnapshot(started: Bool = false) {
        let snapshot = currentSnapshot()
        connectivity.updateCurrentSessionSnapshot(snapshot)
        if started {
            connectivity.sendSessionStarted(snapshot: snapshot)
        } else {
            connectivity.sendSessionUpdate(snapshot: snapshot)
        }
    }

    private func applyRemoteControl() {
        guard let control = connectivity.receivedSessionControl else { return }
        switch control.action {
        case .pause:
            engine.pause()
        case .resume:
            engine.resume()
        case .stop:
            stopAndDismiss(sendStopMessage: true)
            connectivity.clearReceivedSessionControl()
            return
        }
        connectivity.clearReceivedSessionControl()
        sendCurrentSnapshot()
    }

    private func stopAndDismiss(sendStopMessage: Bool) {
        engine.stop()
        workoutManager?.endWorkout()
        if sendStopMessage {
            connectivity.sendSessionStopped()
        }
        onDismiss()
    }
}

private final class WatchMuteState: ObservableObject {
    @Published var hapticsMuted = false
    @Published var soundsMuted = false
}
