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
    @State private var phoneSessionToPresent: IntervalSet?
    @State private var watchSessionToPresent: IntervalSet?
    @State private var restoreState: SessionState?
    @State private var showResumeAlert = false
    @State private var pendingResumeSet: IntervalSet?

    var body: some View {
        HomeView(startSession: { set in
            SessionPersistence.clear()
            restoreState = nil
            watchSessionToPresent = nil
            phoneSessionToPresent = set
        })
        .tint(AppTheme.primary)
        .preferredColorScheme(useLightMode ? .light : nil)
        .fullScreenCover(isPresented: Binding(
            get: { phoneSessionToPresent != nil || watchSessionToPresent != nil },
            set: {
                if !$0 {
                    if phoneSessionToPresent != nil {
                        SessionPersistence.clear()
                        restoreState = nil
                    }
                    phoneSessionToPresent = nil
                    watchSessionToPresent = nil
                }
            }
        )) {
            if let set = watchSessionToPresent {
                WatchMirrorSessionView(
                    set: set,
                    onDismiss: { watchSessionToPresent = nil }
                )
            } else if let set = phoneSessionToPresent {
                LiveSessionView(
                    set: set,
                    restoreState: restoreState,
                    onDismiss: {
                        SessionPersistence.clear()
                        phoneSessionToPresent = nil
                        restoreState = nil
                    }
                )
            }
        }
        .onAppear {
            connectivity.requestSessionState()
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
                    watchSessionToPresent = nil
                    phoneSessionToPresent = set
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
                connectivity.requestSessionState()
                syncSetsToWatch()
            }
        }
        .onChange(of: useLightMode) { _, newValue in
            connectivity.sendSettings(useLightMode: newValue)
        }
        .onChange(of: connectivity.watchSessionSnapshot) { _, snapshot in
            syncWatchMirrorPresentation(snapshot: snapshot)
        }
        .onChange(of: connectivity.watchSessionIsActive) { _, isActive in
            if !isActive {
                watchSessionToPresent = nil
            }
        }
    }

    private func syncWatchMirrorPresentation(snapshot: SessionSnapshot?) {
        guard phoneSessionToPresent == nil else { return }
        guard let snapshot else { return }
        guard !snapshot.isCompleted else {
            watchSessionToPresent = nil
            return
        }
        let store = IntervalSetStore(modelContext: modelContext)
        let sets = (try? store.fetchAll()) ?? []
        guard let set = sets.first(where: { $0.id == snapshot.setId }) else { return }
        watchSessionToPresent = set
    }

    private func syncSetsToWatch() {
        let store = IntervalSetStore(modelContext: modelContext)
        let sets = (try? store.fetchAll()) ?? []
        connectivity.sendSetsOnly(sets)
    }
}
