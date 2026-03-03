//
//  WatchMirrorSessionView.swift
//  IntervalMagic
//

import SwiftUI

struct WatchMirrorSessionView: View {
    let set: IntervalSet
    let onDismiss: () -> Void

    @State private var connectivity = WatchConnectivityManager.shared
    @State private var soundsMuted = false
    @State private var hapticsMuted = false

    private var snapshot: SessionSnapshot? {
        connectivity.watchSessionSnapshot
    }

    private var isPaused: Bool {
        snapshot?.isPaused ?? false
    }

    private var currentInterval: Interval? {
        guard let snapshot else { return nil }
        guard set.intervals.indices.contains(snapshot.intervalIndex) else { return nil }
        return set.intervals[snapshot.intervalIndex]
    }

    private var nextInterval: Interval? {
        guard let snapshot else { return nil }
        let nextIndex = snapshot.intervalIndex + 1
        if set.intervals.indices.contains(nextIndex) {
            return set.intervals[nextIndex]
        }
        switch set.cycleMode {
        case .fixed(let totalCycles):
            guard snapshot.cycle < totalCycles else { return nil }
            return set.intervals.first
        case .infinite:
            return set.intervals.first
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let snapshot {
                    Text(cycleText(for: snapshot))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Text(currentInterval?.name ?? set.name)
                    .font(.title2)

                Text(formatTime(snapshot?.timeRemaining ?? 0))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))

                if let next = nextInterval {
                    VStack(spacing: 4) {
                        Text("Next")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(next.name)
                            .font(.subheadline)
                        if let cueText = cueText(for: next.cueType) {
                            Text(cueText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: 16) {
                    if isPaused {
                        HStack(spacing: 16) {
                            Button {
                                connectivity.sendSessionControl(action: .resume)
                            } label: {
                                Label("Continue", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(role: .destructive) {
                                connectivity.sendSessionControl(action: .stop)
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        HStack(spacing: 16) {
                            Button {
                                connectivity.sendSessionControl(action: .pause)
                            } label: {
                                Label("Pause", systemImage: "pause.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(role: .destructive) {
                                connectivity.sendSessionControl(action: .stop)
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    HStack(spacing: 16) {
                        Button {
                            soundsMuted.toggle()
                            connectivity.sendMuteUpdate(soundsMuted: soundsMuted, hapticsMuted: hapticsMuted)
                        } label: {
                            Image(systemName: soundsMuted ? "speaker.slash" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundStyle(soundsMuted ? .secondary : .primary)
                        }
                        .accessibilityLabel(soundsMuted ? "Sound off" : "Sound on")
                        .accessibilityHint("Toggles watch cue sounds")

                        Button {
                            hapticsMuted.toggle()
                            connectivity.sendMuteUpdate(soundsMuted: soundsMuted, hapticsMuted: hapticsMuted)
                        } label: {
                            Image(systemName: hapticsMuted ? "hand.raised.slash.fill" : "waveform")
                                .font(.title2)
                                .foregroundStyle(hapticsMuted ? .secondary : .primary)
                        }
                        .accessibilityLabel(hapticsMuted ? "Haptics off" : "Haptics on")
                        .accessibilityHint("Toggles watch cue haptics")
                    }
                }
            }
            .padding()
            .navigationTitle("Watch Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                }
            }
            .onAppear {
                soundsMuted = connectivity.mirrorMuteUpdate.soundsMuted
                hapticsMuted = connectivity.mirrorMuteUpdate.hapticsMuted
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let remainder = max(0, seconds) % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    private func cycleText(for snapshot: SessionSnapshot) -> String {
        switch set.cycleMode {
        case .fixed(let totalCycles):
            return "Cycle \(snapshot.cycle) of \(totalCycles)"
        case .infinite:
            return "Cycle \(snapshot.cycle)"
        }
    }

    private func cueText(for cueType: CueType) -> String? {
        switch cueType {
        case .none:
            return "No cue"
        case .haptic(let cue):
            return "Haptic \(cue.displayName)"
        case .sound(let cue):
            return "Sound \(cue.displayName)"
        case .both(let hapticCue, let soundCue):
            return "\(hapticCue.displayName) + \(soundCue.displayName)"
        }
    }
}
