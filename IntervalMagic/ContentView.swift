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
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("useLightMode") private var useLightMode = false
    @State private var connectivity = WatchConnectivityManager.shared
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
            connectivity.sendSettings(useLightMode: useLightMode)
            syncSetsToWatch()
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                syncSetsToWatch()
            }
        }
        .onChange(of: useLightMode) { _, newValue in
            connectivity.sendSettings(useLightMode: newValue)
        }
    }

    private func syncSetsToWatch() {
        let store = IntervalSetStore(modelContext: modelContext)
        let sets = (try? store.fetchAll()) ?? []
        connectivity.sendSetsOnly(sets)
    }
}
