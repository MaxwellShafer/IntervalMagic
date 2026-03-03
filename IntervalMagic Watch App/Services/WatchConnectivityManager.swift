//
//  WatchConnectivityManager.swift
//  IntervalMagic Watch App
//

import Foundation
import WatchConnectivity

@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    private var session: WCSession?

    private(set) var intervalSets: [IntervalSet] = []
    private(set) var pendingStartSetId: UUID?
    private(set) var receivedSessionControl: SessionControl?
    private(set) var sessionControlEvent = UUID()
    private(set) var receivedMuteUpdate = MuteUpdate(soundsMuted: false, hapticsMuted: false)
    private(set) var appSettings = AppSettings(useLightMode: false)

    private var currentSessionSnapshot: SessionSnapshot?
    private var hasActiveSession = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func clearPendingStart() {
        pendingStartSetId = nil
    }

    func clearReceivedSessionControl() {
        receivedSessionControl = nil
    }

    func sendSessionStarted(snapshot: SessionSnapshot) {
        currentSessionSnapshot = snapshot
        hasActiveSession = true
        sendToPhone(.sessionStarted(snapshot))
    }

    func sendSessionUpdate(snapshot: SessionSnapshot) {
        currentSessionSnapshot = snapshot
        hasActiveSession = !snapshot.isCompleted
        sendToPhone(.sessionUpdate(snapshot))
    }

    func sendSessionStopped() {
        currentSessionSnapshot = nil
        hasActiveSession = false
        sendToPhone(.sessionStopped)
    }

    func sendSessionCompleted() {
        currentSessionSnapshot = nil
        hasActiveSession = false
        sendToPhone(.sessionCompleted)
    }

    func updateCurrentSessionSnapshot(_ snapshot: SessionSnapshot) {
        currentSessionSnapshot = snapshot
        hasActiveSession = !snapshot.isCompleted
    }

    private func sendToPhone(_ message: WatchToPhoneMessage) {
        guard let session else { return }
        guard let data = try? JSONEncoder().encode(message),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil)
        } else {
            session.transferUserInfo(dict)
        }
    }

    private func decodeAndApply(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let message = try? JSONDecoder().decode(PhoneToWatchMessage.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.apply(message)
        }
    }

    private func apply(_ message: PhoneToWatchMessage) {
        switch message {
        case .syncSets(let payload):
            intervalSets = payload.intervalSets
            if let settings = payload.appSettings {
                appSettings = settings
                UserDefaults.standard.set(settings.useLightMode, forKey: "useLightMode")
            }
            if case .startSet(let id) = payload.command {
                pendingStartSetId = id
            }
        case .sessionControl(let control):
            receivedSessionControl = control
            sessionControlEvent = UUID()
        case .muteUpdate(let muteUpdate):
            receivedMuteUpdate = muteUpdate
        case .settingsUpdate(let settings):
            appSettings = settings
            UserDefaults.standard.set(settings.useLightMode, forKey: "useLightMode")
        case .requestSessionState:
            if hasActiveSession, let snapshot = currentSessionSnapshot {
                sendToPhone(.sessionUpdate(snapshot))
            } else {
                sendToPhone(.noActiveSession)
            }
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decodeAndApply(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decodeAndApply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        decodeAndApply(userInfo)
    }
}
