//
//  AddIntervalSheet.swift
//  IntervalMagic
//

import SwiftUI

struct AddIntervalSheet: View {
    @Binding var isPresented: Bool
    let onSave: (Interval) -> Void

    @State private var name = ""
    @State private var durationSeconds = 30
    @State private var cueType: CueType = .haptic(.single)

    var body: some View {
        NavigationStack {
            Form {
                Section("Interval") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Duration (seconds)")
                        Spacer()
                        TextField("", value: $durationSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Stepper("", value: $durationSeconds, in: 1...3600)
                            .labelsHidden()
                    }
                }

                Section {
                    CueSelectionView(cueType: $cueType)
                }

                Section {
                    HStack {
                        Button("Preview haptic") {
                            HapticCueService.shared.play(cueType: cueType)
                        }
                        Spacer()
                        Button("Preview sound") {
                            SoundCueService.shared.play(cueType: cueType)
                        }
                    }
                }
            }
            .navigationTitle("Add Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let interval = Interval(
                            name: name.isEmpty ? "Interval" : name,
                            durationSeconds: max(1, durationSeconds),
                            cueType: cueType
                        )
                        onSave(interval)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || durationSeconds < 1)
                }
            }
        }
    }
}
