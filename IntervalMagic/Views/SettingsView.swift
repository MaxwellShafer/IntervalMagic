//
//  SettingsView.swift
//  IntervalMagic
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IntervalSetEntity.name) private var setEntities: [IntervalSetEntity]
    @State private var showCustomHaptics = false
    @State private var showDeleteAllConfirmation = false
    @AppStorage("useLightMode") private var useLightMode = false
    @AppStorage("intervalOutlineShape") private var intervalOutlineShapeRaw = IntervalOutlineShape.circle.rawValue
    @AppStorage("intervalOutlineColor") private var intervalOutlineColorData: Data = try! NSKeyedArchiver.archivedData(withRootObject: UIColor.systemBlue, requiringSecureCoding: false)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Light mode", isOn: $useLightMode)
                } footer: {
                    Text("Toggle on for light mode, and off for dark mode.")
                }

                Section("Interval Visualization") {
                    Picker("Shape", selection: Binding(
                        get: { IntervalOutlineShape(rawValue: intervalOutlineShapeRaw) ?? .circle },
                        set: { intervalOutlineShapeRaw = $0.rawValue }
                    )) {
                        ForEach(IntervalOutlineShape.allCases) { shape in
                            Text(shape.displayName).tag(shape)
                        }
                    }

                    ColorPicker("Color", selection: Binding(
                        get: {
                            if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: intervalOutlineColorData) {
                                return Color(uiColor)
                            }
                            return .blue
                        },
                        set: { newColor in
                            let uiColor = UIColor(newColor)
                            if let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
                                intervalOutlineColorData = data
                            }
                        }
                    ))
                }

                Section {
                    Button {
                        showCustomHaptics = true
                    } label: {
                        Label("Custom Haptics", systemImage: "waveform.path")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete all interval sets", systemImage: "trash")
                    }
                    .disabled(setEntities.isEmpty)
                } footer: {
                    if setEntities.isEmpty {
                        Text("There are no interval sets to delete.")
                    } else {
                        Text("This cannot be undone. All interval sets will be permanently deleted.")
                    }
                }
            }
            .confirmationDialog("Delete all interval sets?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) {
                    let store = IntervalSetStore(modelContext: modelContext)
                    try? store.deleteAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(setEntities.isEmpty ? "There are no interval sets to delete." : "All interval sets will be permanently deleted. This cannot be undone.")
            }
            .sheet(isPresented: $showCustomHaptics) {
                CustomHapticsListView()
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

