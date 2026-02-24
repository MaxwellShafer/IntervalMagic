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
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.intervalSets = payload.intervalSets
            if case .startSet(let id) = payload.command {
                self?.pendingStartSetId = id
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
