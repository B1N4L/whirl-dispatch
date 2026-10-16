//
//  SupervisorSplitView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-16.
//

import SwiftUI

struct SupervisorSplitView: View {
    @Bindable var authVM: AuthViewModel
    @State private var selectedMenu: SupervisorMenu? = .fleetMap
    @State private var columnVisibility: NavigationSplitViewVisibility = .all


    enum SupervisorMenu: String, CaseIterable, Identifiable {
        case fleetMap = "Fleet Map"
        case activeDispatches = "Active Dispatches"
        case expenseApprovals = "Expense Approvals"
        case teamStatus = "Technician Roster"
        case profile = "Supervisor Profile"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .fleetMap: return "map.fill"
            case .activeDispatches: return "list.bullet.clipboard.fill"
            case .expenseApprovals: return "checkmark.seal.fill"
            case .teamStatus: return "person.3.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }


    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // sidebar column for ipad command center navigation
            List(SupervisorMenu.allCases, selection: $selectedMenu) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                        .font(.appSubheadline)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Command Center")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Supervisor")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.statusAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.statusAmber.opacity(0.12))
                        )
                }
            }
        } content: {
            // middle content list column
            Group {
                if let menu = selectedMenu {
                    switch menu {
                    case .fleetMap:
                        VStack(spacing: 12) {
                            Text("Facility Zones")
                                .font(.appHeadline)
                            List {
                                Text("Zone 1: Metro Commercial HQ")
                                Text("Zone 2: Sub-Basement Chiller")
                                Text("Zone 3: North Plant Room")
                            }
                        }
                    case .activeDispatches:
                        List {
                            Text("WO-2026-4401: Hemas Chiller Fault")
                            Text("WO-2026-4402: Rooftop AHU Inspection")
                            Text("WO-2026-4403: Emergency Leak Repair")
                        }
                    case .expenseApprovals:
                        List {
                            Text("Supply House Receipt - $240.00 (Pending)")
                            Text("Refrigerant R410A - $185.00 (Pending)")
                        }
                    case .teamStatus:
                        List {
                            Text("Nuwan Silva (Field Tech) - Active On-Site")
                            Text("Kasun Perera (Lead Tech) - En Route")
                            Text("Dinesh Fernando (Field Tech) - Available")
                        }
                    case .profile:
                        Text("Settings & Session")
                    }
                } else {
                    Text("Select a category")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(selectedMenu?.rawValue ?? "Operations")
        } detail: {
            // right primary detail pane
            Group {
                if let menu = selectedMenu {
                    switch menu {
                    case .fleetMap:
                        VStack(spacing: 16) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.accentBlue)
                            Text("Interactive Fleet & Facility Tracker")
                                .font(.appTitle)
                            Text("MapKit streaming GPS coordinates of all active technicians.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .activeDispatches:
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet.clipboard.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.brandNavy)
                            Text("Dispatch Management & Reassignment")
                                .font(.appTitle)
                            Text("Review dispatched plant room work orders and assign lead techs.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .expenseApprovals:
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.statusGreen)
                            Text("Optical Receipt Verification Queue")
                                .font(.appTitle)
                            Text("Approve or reject field parts purchases with OCR validation.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .teamStatus:
                        VStack(spacing: 16) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.accentBlue)
                            Text("Field Technician Roster & Safety Logs")
                                .font(.appTitle)
                            Text("Inspect live geofence breaches, attendance sessions, and certifications.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .profile:
                        ProfileTabView(authVM: authVM)
                    }
                } else {
                    Text("Select an operation from the sidebar")
                        .font(.appBody)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}


struct SupervisorCompactView: View {
    @Bindable var authVM: AuthViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "map.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.accentBlue)
                    Text("Fleet Map & Facilities")
                        .font(.appHeadline)
                    Spacer()
                }
                .navigationTitle("Fleet Map")
            }
            .tabItem {
                Label("Fleet Map", systemImage: "map.fill")
            }
            .tag(0)

            NavigationStack {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "list.bullet.clipboard.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.brandNavy)
                    Text("Dispatches & Assignments")
                        .font(.appHeadline)
                    Spacer()
                }
                .navigationTitle("Dispatches")
            }
            .tabItem {
                Label("Dispatches", systemImage: "list.bullet.clipboard.fill")
            }
            .tag(1)

            NavigationStack {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.statusGreen)
                    Text("Expense Approvals Queue")
                        .font(.appHeadline)
                    Spacer()
                }
                .navigationTitle("Approvals")
            }
            .tabItem {
                Label("Approvals", systemImage: "checkmark.seal.fill")
            }
            .tag(2)

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
}
