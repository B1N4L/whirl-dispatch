//
//  FieldTechTabView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-15.
//

import SwiftUI

struct FieldTechTabView: View {
    @Bindable var authVM: AuthViewModel
    @State private var selectedTab: Int = 0
    @State private var offlineManager = OfflineModeManager.shared


    var body: some View {
        VStack(spacing: 0) {
            // show offline alert banner if plant room mode is active or changes queued
            if offlineManager.isPlantRoomOffline || offlineManager.pendingSyncCount > 0 {
                OfflineBanner(
                    isOffline: offlineManager.isPlantRoomOffline,
                    pendingCount: offlineManager.pendingSyncCount
                ) {
                    // manual sync trigger
                    Task {
                        await offlineManager.syncPendingChanges()
                    }
                }
            }

            TabView(selection: $selectedTab) {
                // tab 1: work orders dispatch feed
                WorkOrderListView()
                    .tabItem {
                        Label("Work Orders", systemImage: "wrench.and.screwdriver.fill")
                    }
                    .tag(0)


                // tab 2: site attendance and clock-in
                AttendanceView()
                    .tabItem {
                        Label("Attendance", systemImage: "clock.badge.checkmark.fill")
                    }
                    .tag(1)


                // tab 3: emergency field expenses
                NavigationStack {
                    VStack {
                        Spacer()
                        Image(systemName: "receipt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.statusAmber)
                        Text("Emergency Field Parts")
                            .font(.appHeadline)
                            .padding(.top, 8)
                        Text("Log parts purchased from supply houses")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .navigationTitle("Expenses")
                }
                .tabItem {
                    Label("Expenses", systemImage: "receipt.fill")
                }
                .tag(2)


                // tab 4: technician profile & session
                NavigationStack {
                    ProfileTabView(authVM: authVM)
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
            }
            .tint(Color.brandNavy)
        }
        .task {
            // refresh sync pending count on load
            await offlineManager.refreshPendingCount()
        }
    }
}


#Preview {
    FieldTechTabView(authVM: AuthViewModel())
}
