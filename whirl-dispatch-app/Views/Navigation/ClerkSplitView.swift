//
//  ClerkSplitView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-16.
//

import SwiftUI

struct ClerkSplitView: View {
    @Bindable var authVM: AuthViewModel
    @State private var selectedMenu: ClerkMenu? = .invoicingQueue
    @State private var columnVisibility: NavigationSplitViewVisibility = .all


    enum ClerkMenu: String, CaseIterable, Identifiable {
        case invoicingQueue = "Invoicing Queue"
        case approvedExpenses = "Approved Expenses"
        case revenueTelemetry = "Financial Telemetry"
        case profile = "Clerk Profile"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .invoicingQueue: return "doc.text.fill"
            case .approvedExpenses: return "creditcard.fill"
            case .revenueTelemetry: return "chart.bar.xaxis"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }


    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // sidebar column for clerk
            List(ClerkMenu.allCases, selection: $selectedMenu) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                        .font(.appSubheadline)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Billing Hub")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Billing Clerk")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.statusGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.statusGreen.opacity(0.12))
                        )
                }
            }
        } content: {
            // middle column list
            Group {
                if let menu = selectedMenu {
                    switch menu {
                    case .invoicingQueue:
                        List {
                            Text("INV-2026-001: Hemas HQ - $758.70 (Ready)")
                            Text("INV-2026-002: Rooftop Coil - $1,240.00 (Pending)")
                            Text("INV-2026-003: Motor Replacement - $450.00 (Draft)")
                        }
                    case .approvedExpenses:
                        List {
                            Text("Supply House Fasteners - $85.00 (Approved)")
                            Text("Compressor Valve Seal - $140.00 (Approved)")
                        }
                    case .revenueTelemetry:
                        List {
                            Text("Facility Revenue Summary")
                            Text("Labor Hours vs Parts Cost")
                            Text("Monthly Billed Breakdown")
                        }
                    case .profile:
                        Text("Clerk Account Settings")
                    }
                } else {
                    Text("Select a billing category")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(selectedMenu?.rawValue ?? "Invoicing")
        } detail: {
            // detail pane
            Group {
                if let menu = selectedMenu {
                    switch menu {
                    case .invoicingQueue:
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.brandNavy)
                            Text("Automated Invoice Breakdown & Markup")
                                .font(.appTitle)
                            Text("Labor hours multiplied by contract rate plus parts markup calculation.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .approvedExpenses:
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.statusGreen)
                            Text("Supervisor Approved Field Claims")
                                .font(.appTitle)
                            Text("All parts verified and signed off for client billing inclusion.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .revenueTelemetry:
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 56))
                                .foregroundColor(Color.accentBlue)
                            Text("Swift Charts Financial Telemetry")
                                .font(.appTitle)
                            Text("Interactive bar and donut charts illustrating monthly margins.")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                    case .profile:
                        ProfileTabView(authVM: authVM)
                    }
                } else {
                    Text("Select an invoice from the list")
                        .font(.appBody)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}


struct ClerkCompactView: View {
    @Bindable var authVM: AuthViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.brandNavy)
                    Text("Invoicing Queue")
                        .font(.appHeadline)
                    Spacer()
                }
                .navigationTitle("Invoicing")
            }
            .tabItem {
                Label("Invoicing", systemImage: "doc.text.fill")
            }
            .tag(0)

            NavigationStack {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.statusGreen)
                    Text("Approved Claims")
                        .font(.appHeadline)
                    Spacer()
                }
                .navigationTitle("Claims")
            }
            .tabItem {
                Label("Claims", systemImage: "creditcard.fill")
            }
            .tag(1)

            NavigationStack {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundColor(Color.accentBlue)
                    Text("Revenue Telemetry")
                        .font(.appHeadline)
                    Spacer()
                }
                .navigationTitle("Charts")
            }
            .tabItem {
                Label("Charts", systemImage: "chart.bar.xaxis")
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
