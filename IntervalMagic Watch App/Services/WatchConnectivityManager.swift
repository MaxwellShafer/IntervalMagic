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
    private(set) var appSettings = AppSettings(useLightMode: false)

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
        case .settingsUpdate(let settings):
            appSettings = settings
            UserDefaults.standard.set(settings.useLightMode, forKey: "useLightMode")
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
