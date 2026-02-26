//
//  SettingsView.swift
//  IntervalMagic
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage("useLightMode") private var useLightMode = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Light mode", isOn: $useLightMode)
                } footer: {
                    Text("When on, the app uses a light appearance. When off, the system appearance is used.")
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
