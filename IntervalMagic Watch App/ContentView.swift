//
//  ContentView.swift
//  IntervalMagic Watch App
//
//  Created by Maxwell Shafer on 2/23/26.
//

import SwiftUI

struct ContentView: View {
    @State private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        NavigationStack {
            StartView()
        }
        .preferredColorScheme(connectivity.appSettings.useLightMode ? .light : nil)
    }
}

#Preview {
    ContentView()
}
