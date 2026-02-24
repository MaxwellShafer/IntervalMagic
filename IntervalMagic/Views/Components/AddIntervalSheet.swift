//
//  AddIntervalSheet.swift
//  IntervalMagic
//

import SwiftUI

struct AddIntervalSheet: View {
    @Binding var isPresented: Bool
    var suggestedName: String?
    let onSave: (Interval) -> Void

    @State private var name = ""
    @State private var durationSeconds = 12
    @State private var cueType: CueType = .none

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
                        let displayName = name.trimmingCharacters(in: .whitespaces).isEmpty
                            ? (suggestedName ?? "Interval")
                            : name
                        let interval = Interval(
                            name: displayName,
                            durationSeconds: max(1, durationSeconds),
                            cueType: cueType
                        )
                        onSave(interval)
                        isPresented = false
                    }
                    .disabled(durationSeconds < 1)
                }
            }
        }
    }
}
