//
//  ContentView.swift
//  IntervalMagic
//
//  Created by Maxwell Shafer on 2/23/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var activeSessionSet: IntervalSet?
    @State private var restoreState: SessionState?
    @State private var showLiveSession = false
    @State private var showResumeAlert = false
    @State private var pendingResumeSet: IntervalSet?

    var body: some View {
        HomeView(startSession: { set in
            SessionPersistence.clear()
            activeSessionSet = set
            restoreState = nil
            showLiveSession = true
        })
            .fullScreenCover(isPresented: $showLiveSession) {
                if let set = activeSessionSet {
                    LiveSessionView(
                        set: set,
                        restoreState: restoreState,
                        onDismiss: {
                            SessionPersistence.clear()
                            activeSessionSet = nil
                            restoreState = nil
                            showLiveSession = false
                        }
                    )
                }
            }
            .onAppear {
                if let state = SessionPersistence.load() {
                    let store = IntervalSetStore(modelContext: modelContext)
                    let sets = (try? store.fetchAll()) ?? []
                    if let set = sets.first(where: { $0.id == state.setId }) {
                        pendingResumeSet = set
                        showResumeAlert = true
                    }
                }
            }
            .alert("Resume session?", isPresented: $showResumeAlert) {
                Button("Resume") {
                    if let set = pendingResumeSet, let state = SessionPersistence.load() {
                        activeSessionSet = set
                        restoreState = state
                        showLiveSession = true
                    }
                    pendingResumeSet = nil
                }
                Button("Cancel", role: .cancel) {
                    SessionPersistence.clear()
                    pendingResumeSet = nil
                }
            } message: {
                Text("You have an unfinished interval session.")
            }
    }
}
