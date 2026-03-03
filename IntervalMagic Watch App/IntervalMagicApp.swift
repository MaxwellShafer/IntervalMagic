//
//  IntervalMagicApp.swift
//  IntervalMagic Watch App
//
//  Created by Maxwell Shafer on 2/23/26.
//

import SwiftUI

@main
struct IntervalMagic_Watch_AppApp: App {
    @State private var connectivity = WatchConnectivityManager.shared

    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(connectivity.appSettings.useLightMode ? .light : nil)
        }
    }
}
