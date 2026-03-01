//
//  LiveSessionView.swift
//  IntervalMagic
//

import SwiftUI
import Combine
import UIKit

struct LiveSessionView: View {
    let set: IntervalSet
    var restoreState: SessionState?
    let onDismiss: () -> Void

    @StateObject private var engine: IntervalSetEngine
    @StateObject private var muteState = MuteState()
    @State private var showStopConfirmation = false
    @State private var hasBegun = false

    @AppStorage("intervalOutlineShape") private var intervalOutlineShapeRaw = IntervalOutlineShape.circle.rawValue
    @AppStorage("intervalOutlineColor") private var intervalOutlineColorData: Data = try! NSKeyedArchiver.archivedData(withRootObject: UIColor.systemBlue, requiringSecureCoding: false)

    init(set: IntervalSet, restoreState: SessionState? = nil, onDismiss: @escaping () -> Void) {
        self.set = set
        self.restoreState = restoreState
        self.onDismiss = onDismiss
        _engine = StateObject(wrappedValue: IntervalSetEngine(set: set))
    }

    private var selectedShape: IntervalOutlineShape {
        IntervalOutlineShape(rawValue: intervalOutlineShapeRaw) ?? .circle
    }

    private var selectedColor: Color {
        if let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(intervalOutlineColorData) as? UIColor {
            return Color(uiColor)
        }
        return .blue
    }

    var body: some View {
        NavigationStack {
            TimelineView(.animation) { context in
                let now = context.date
                contentView(now: now)
            }
            .padding()
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if engine.isPaused {
                            engine.stop()
                            SessionPersistence.clear()
                            onDismiss()
                        } else {
                            showStopConfirmation = true
                        }
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
                    if !muteState.soundsMuted {
                        SoundCueService.shared.play(cueType: cueType)
                    }
                }
                if let state = restoreState {
                    engine.restore(
                        intervalIndex: state.intervalIndex,
                        cycle: state.cycle,
                        timeRemaining: state.timeRemaining,
                        isPaused: state.isPaused
                    )
                    hasBegun = true
                    if !state.isPaused {
                        engine.resume()
                    }
                } else {
                    // Wait for user to press Begin
                    hasBegun = false
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

    @ViewBuilder private func contentView(now: Date) -> some View {
        VStack(spacing: 24) {
            if engine.isCompleted {
                Text("Done")
                    .font(.largeTitle)
                Button("Close", action: onDismiss)
            } else {
                if !hasBegun {
                    // Pre-start screen with Begin button
                    Text(set.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .underline()
                    if let total = engine.totalCycles {
                        Text("Ready: \(total) cycle\(total == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        hasBegun = true
                        engine.start()
                    } label: {
                        Label("Begin", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 56)
                    }
                    .buttonStyle(.borderedProminent)
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
                        Group {
                            Text(name)
                                .font(.title2)
                        }
                        .id(name)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }

                    IntervalOutlineProgressView(
                        shape: selectedShape,
                        progress: progressForCurrentInterval(),
                        baseColor: .white,
                        progressColor: selectedColor,
                        lineWidth: 6,
                        inset: 6
                    ) {
                        Text(formatTime(engine.timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .id(engine.stateSnapshot.intervalIndex)
                    }
                    .frame(width: 360, height: 360)
                    .animation(.easeIn(duration: 0.35), value: engine.stateSnapshot.intervalIndex)
                    

                    if let nextInterval = engine.nextInterval {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(nextInterval.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let cueStr = engine.cueStyleString(for: nextInterval.cueType) {
                                Text(cueStr)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("next_\(engine.stateSnapshot.intervalIndex)")
                        .transition(.opacity)
                    }

                    VStack(spacing: 16) {
                        if engine.isPaused {
                            HStack(spacing: 16) {
                                Button {
                                    engine.resume()
                                } label: {
                                    Label("Continue", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)

                                Button(role: .destructive) {
                                    engine.stop()
                                    SessionPersistence.clear()
                                    onDismiss()
                                } label: {
                                    Label("Stop", systemImage: "stop.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        } else {
                            Button {
                                engine.pause()
                            } label: {
                                Label("Pause", systemImage: "pause.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        HStack(spacing: 16) {
                            Button {
                                muteState.soundsMuted.toggle()
                            } label: {
                                Image(systemName: muteState.soundsMuted ? "speaker.slash" : "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundStyle(muteState.soundsMuted ? .secondary : .primary)
                            }
                            .accessibilityLabel(muteState.soundsMuted ? "Sound off" : "Sound on")
                            .accessibilityHint("Toggles whether cue plays sound")

                            Button {
                                muteState.hapticsMuted.toggle()
                            } label: {
                                Image(systemName: muteState.hapticsMuted ? "hand.raised.slash.fill" : "waveform")
                                    .font(.title2)
                                    .foregroundStyle(muteState.hapticsMuted ? .secondary : .primary)
                            }
                            .accessibilityLabel(muteState.hapticsMuted ? "Haptics off" : "Haptics on")
                            .accessibilityHint("Toggles whether cue plays haptics")
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: engine.stateSnapshot.intervalIndex)
    }

    private func progressForCurrentInterval() -> Double {
        guard let interval = engine.currentInterval else { return 0 }
        let total = max(1, interval.durationSeconds)
        let remaining = max(0, engine.timeRemaining)
        let elapsed = Double(total - remaining)
        return min(max(elapsed / Double(total), 0), 1)
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private final class MuteState: ObservableObject {
    @Published var soundsMuted = false
    @Published var hapticsMuted = false
}
