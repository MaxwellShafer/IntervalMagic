//
//  IntervalMagicApp.swift
//  IntervalMagic Watch App
//
//  Created by Maxwell Shafer on 2/23/26.
//

import SwiftUI

@main
struct IntervalMagic_Watch_AppApp: App {
    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
