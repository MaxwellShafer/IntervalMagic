//
//  SettingsView.swift
//  IntervalMagic
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Binding var isPresented: Bool
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
                            if let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(intervalOutlineColorData) as? UIColor {
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

