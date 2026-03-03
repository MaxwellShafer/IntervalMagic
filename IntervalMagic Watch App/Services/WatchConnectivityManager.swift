//
//  WatchConnectivityManager.swift
//  IntervalMagic Watch App
//

import Foundation
import WatchConnectivity

@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    private static let savedIntervalSetsKey = "savedIntervalSets"
    private var session: WCSession?

    private(set) var intervalSets: [IntervalSet] = []
    private(set) var pendingStartSetId: UUID?
    private(set) var appSettings = AppSettings(
        useLightMode: UserDefaults.standard.bool(forKey: "useLightMode")
    )
    private(set) var phoneRequestedBegin = false

    override init() {
        super.init()
        loadPersistedSets()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func clearPendingStart() {
        pendingStartSetId = nil
    }

    func clearPhoneRequestedBegin() {
        phoneRequestedBegin = false
    }

    func sendWatchSessionStarted() {
        sendToPhone(.watchSessionStarted)
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

    private func persistSets() {
        guard let data = try? JSONEncoder().encode(intervalSets) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedIntervalSetsKey)
    }

    private func loadPersistedSets() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedIntervalSetsKey),
              let sets = try? JSONDecoder().decode([IntervalSet].self, from: data) else { return }
        intervalSets = sets
    }

    private func apply(_ message: PhoneToWatchMessage) {
        switch message {
        case .syncSets(let payload):
            intervalSets = payload.intervalSets
            persistSets()
            if let settings = payload.appSettings {
                appSettings = settings
                UserDefaults.standard.set(settings.useLightMode, forKey: "useLightMode")
            }
            if case .startSet(let id) = payload.command {
                pendingStartSetId = id
            } else {
                pendingStartSetId = nil
            }
        case .settingsUpdate(let settings):
            appSettings = settings
            UserDefaults.standard.set(settings.useLightMode, forKey: "useLightMode")
        case .beginSession:
            phoneRequestedBegin = true
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
