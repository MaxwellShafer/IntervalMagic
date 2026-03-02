//
//  SoundCueService.swift
//  IntervalMagic
//

import Foundation
import AVFoundation

// #region agent log
private func _debugLog(_ message: String, _ data: [String: Any] = [:], hypothesisId: String = "H") {
    let logPath = "/Users/maxshafer/Development/CursorProjects/IntervalMagic/.cursor/debug-777030.log"
    let payload: [String: Any] = ["sessionId": "777030", "message": message, "data": data, "timestamp": Int(Date().timeIntervalSince1970 * 1000), "hypothesisId": hypothesisId]
    guard let json = try? JSONSerialization.data(withJSONObject: payload), let line = String(data: json + Data([0x0a]), encoding: .utf8), let d = line.data(using: .utf8) else { return }
    let url = URL(fileURLWithPath: logPath)
    if !FileManager.default.fileExists(atPath: logPath) { try? Data().write(to: url) }
    guard let h = try? FileHandle(forWritingTo: url) else { return }
    h.seekToEndOfFile()
    h.write(d)
    try? h.close()
}
// #endregion

final class SoundCueService {
    static let shared = SoundCueService()
    private var players: [SoundStyle: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
        var loaded: [String] = []
        var missing: [String] = []
        for style in SoundStyle.allCases {
            if let url = Bundle.main.url(forResource: style.rawValue, withExtension: "wav", subdirectory: "Sounds"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[style] = player
                loaded.append(style.rawValue)
            } else {
                missing.append(style.rawValue)
            }
        }
        // #region agent log
        _debugLog("SoundCueService init: players loaded", ["count": players.count, "loaded": loaded.joined(separator: ","), "missing": missing.joined(separator: ",")], hypothesisId: "H3")
        // #endregion
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Cue sounds are non-critical; continue without audio session config
        }
    }

    /// Ensures the audio session is active before playback (fixes first-play on launch or after background).
    private func ensureSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            // #region agent log
            _debugLog("ensureSessionActive succeeded", [:], hypothesisId: "H4")
            // #endregion
        } catch {
            // #region agent log
            _debugLog("ensureSessionActive failed", ["error": "\(error)"], hypothesisId: "H4")
            // #endregion
            // Non-critical; playback may still work
        }
    }

    func play(cueType: CueType, onFinished: (() -> Void)? = nil) {
        let cue: SoundCue?
        switch cueType {
        case .none, .haptic: cue = nil
        case .sound(let s): cue = s
        case .both(_, let s): cue = s
        }
        // #region agent log
        _debugLog("play(cueType:) called", ["cueIsNil": cue == nil, "cueTypeCase": "\(cueType)"], hypothesisId: "H1")
        // #endregion
        guard let cue else { return }
        switch cue {
        case .predefined(let style):
            play(style: style)
            onFinished?()
        case .custom(let id, let waitUntilFinished):
            playCustom(id: id, waitUntilFinished: waitUntilFinished, onFinished: onFinished)
        }
    }

    func play(style: SoundStyle) {
        // #region agent log
        let hasPlayer = players[style] != nil
        _debugLog("play(style:) before ensureSessionActive", ["style": style.rawValue, "hasPlayer": hasPlayer], hypothesisId: "H3")
        // #endregion
        ensureSessionActive()
        if let player = players[style] {
            player.currentTime = 0
            player.play()
            // #region agent log
            _debugLog("play(style:) called player.play()", ["style": style.rawValue], hypothesisId: "H4")
            // #endregion
        }
        // No system sound fallback; only bundle WAVs to avoid unintended haptics and ensure Watch parity.
    }

    /// Custom sound playback from CustomCuesStore. No-op if definition or file not found.
    func playCustom(id: UUID, waitUntilFinished: Bool, onFinished: (() -> Void)? = nil) {
        ensureSessionActive()
        guard let url = CustomCuesStore.shared.fileURL(forCustomSound: id) else {
            onFinished?()
            return
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            onFinished?()
            return
        }
        player.prepareToPlay()
        if waitUntilFinished, let onFinished = onFinished {
            let observer = CustomSoundPlaybackObserver(player: player, onFinished: onFinished)
            objc_setAssociatedObject(player, &customSoundObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            onFinished?()
        }
        player.play()
    }
}

// MARK: - Custom sound playback completion

private final class CustomSoundPlaybackObserver: NSObject, AVAudioPlayerDelegate {
    let onFinished: () -> Void
    init(player: AVAudioPlayer, onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        super.init()
        player.delegate = self
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinished()
    }
}

private var customSoundObserverKey: UInt8 = 0
