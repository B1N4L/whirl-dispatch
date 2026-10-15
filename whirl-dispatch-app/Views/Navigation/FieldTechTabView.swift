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
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var pendingSyncCount: Int = 0


    var body: some View {
        VStack(spacing: 0) {
            // show offline alert banner if network is disconnected in basement
            if !networkMonitor.isConnected || pendingSyncCount > 0 {
                OfflineBanner(
                    isOffline: !networkMonitor.isConnected,
                    pendingCount: pendingSyncCount
                ) {
                    // manual sync trigger
                    Task {
                        _ = await WorkOrderRepository.shared.syncPendingMutations()
                        pendingSyncCount = await OfflineStorageService.shared.getPendingSyncCount()
                    }
                }
            }

            TabView(selection: $selectedTab) {
                // tab 1: work orders dispatch feed
                NavigationStack {
                    VStack {
                        Spacer()
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.accentBlue)
                        Text("Active Work Orders Feed")
                            .font(.appHeadline)
                            .padding(.top, 8)
                        Text("Select a dispatched job to inspect details")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .navigationTitle("Dispatched Jobs")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            if let role = authVM.currentUser?.role {
                                Text(role.displayName)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.brandNavy)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.brandNavy.opacity(0.12))
                                    )
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Work Orders", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(0)


                // tab 2: site attendance and clock-in
                NavigationStack {
                    VStack {
                        Spacer()
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.statusGreen)
                        Text("Site Shift & Geofence")
                            .font(.appHeadline)
                            .padding(.top, 8)
                        Text("Clock in within 150m radius of facility")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .navigationTitle("Site Attendance")
                }
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
            pendingSyncCount = await OfflineStorageService.shared.getPendingSyncCount()
        }
    }
}


#Preview {
    FieldTechTabView(authVM: AuthViewModel())
}
