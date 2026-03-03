//
//  ContentView.swift
//  IntervalMagic Watch App
//
//  Created by Maxwell Shafer on 2/23/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("useLightMode") private var useLightMode = false

    var body: some View {
        NavigationStack {
            StartView()
        }
        .preferredColorScheme(useLightMode ? .light : nil)
    }
}

#Preview {
    ContentView()
}
