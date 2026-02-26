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
    @AppStorage("useLightMode") private var useLightMode = false
    /// Single source of truth: when non-nil, present fullScreenCover with this set (avoids "Preparing session" race).
    @State private var sessionToPresent: IntervalSet?
    @State private var restoreState: SessionState?
    @State private var showResumeAlert = false
    @State private var pendingResumeSet: IntervalSet?

    var body: some View {
        HomeView(startSession: { set in
            SessionPersistence.clear()
            restoreState = nil
            sessionToPresent = set
        })
        .tint(AppTheme.primary)
        .preferredColorScheme(useLightMode ? .light : nil)
        .fullScreenCover(isPresented: Binding(
            get: { sessionToPresent != nil },
            set: { if !$0 { sessionToPresent = nil; restoreState = nil; SessionPersistence.clear() } }
        )) {
            if let set = sessionToPresent {
                LiveSessionView(
                    set: set,
                    restoreState: restoreState,
                    onDismiss: {
                        SessionPersistence.clear()
                        sessionToPresent = nil
                        restoreState = nil
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
                    restoreState = state
                    sessionToPresent = set
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
