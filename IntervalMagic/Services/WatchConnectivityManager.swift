//
//  WatchConnectivityManager.swift
//  IntervalMagic
//

import Foundation
import WatchConnectivity

@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    private var session: WCSession?

    var isReachable: Bool { session?.isReachable ?? false }
    var receivedContext: [String: Any]?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendIntervalSets(_ sets: [IntervalSet], startSetId: UUID? = nil) {
        let payload = SyncPayload(
            intervalSets: sets,
            command: startSetId.map { .startSet(intervalSetId: $0) }
        )
        send(payload)
    }

    func send(_ payload: SyncPayload) {
        guard let session else { return }
        guard let data = try? JSONEncoder().encode(payload),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil)
        } else {
            session.updateApplicationContext(dict)
            session.transferUserInfo(dict)
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    func sessionReachabilityDidChange(_ session: WCSession) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decodeAndStore(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decodeAndStore(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        decodeAndStore(userInfo)
    }

    private func decodeAndStore(_ dict: [String: Any]) {
        receivedContext = dict
    }
}
