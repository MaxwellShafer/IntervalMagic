//
//  WatchConnectivityManager.swift
//  IntervalMagic
//

import Foundation
import WatchConnectivity
import HealthKit

@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    private var session: WCSession?
    private let healthStore = HKHealthStore()

    var isReachable: Bool { session?.isReachable ?? false }
    var watchDidStart = false

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
            command: startSetId.map { .startSet(intervalSetId: $0) },
            appSettings: currentSettings()
        )
        sendToWatch(.syncSets(payload), persistForBackground: true)
        if startSetId != nil {
            launchWatchAppForStart()
        }
    }

    func sendSetsOnly(_ sets: [IntervalSet]) {
        sendIntervalSets(sets, startSetId: nil)
    }

    func sendSettings(useLightMode: Bool) {
        sendToWatch(.settingsUpdate(AppSettings(useLightMode: useLightMode)), persistForBackground: true)
    }

    func sendBeginSession() {
        sendToWatch(.beginSession)
    }

    func resetWatchDidStart() {
        watchDidStart = false
    }

    private func currentSettings() -> AppSettings {
        AppSettings(useLightMode: UserDefaults.standard.bool(forKey: "useLightMode"))
    }

    private func sendToWatch(_ message: PhoneToWatchMessage, persistForBackground: Bool = false) {
        guard let session else { return }
        guard let data = try? JSONEncoder().encode(message),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil)
        }
        if persistForBackground || !session.isReachable {
            try? session.updateApplicationContext(dict)
            session.transferUserInfo(dict)
        }
    }

    private func launchWatchAppForStart() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        healthStore.startWatchApp(with: configuration) { _, _ in }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    func sessionReachabilityDidChange(_ session: WCSession) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decodeAndApply(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decodeAndApply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        decodeAndApply(userInfo)
    }

    private func decodeAndApply(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let message = try? JSONDecoder().decode(WatchToPhoneMessage.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.apply(message)
        }
    }

    private func apply(_ message: WatchToPhoneMessage) {
        switch message {
        case .watchSessionStarted:
            watchDidStart = true
        }
    }
}
