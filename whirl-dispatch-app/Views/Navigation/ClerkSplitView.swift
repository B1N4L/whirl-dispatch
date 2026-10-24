//
//  ClerkSplitView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-16.
//

import SwiftUI
import UIKit

struct ClerkSplitView: View {
    @Bindable var authVM: AuthViewModel
    @State private var viewModel = BillingViewModel()
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
                        invoicingQueueContentList

                    case .approvedExpenses:
                        approvedExpensesContentList

                    case .revenueTelemetry:
                        telemetryPlaceholderList

                    case .profile:
                        ProfileTabView(authVM: authVM)
                    }
                } else {
                    Text("Select a billing category")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(selectedMenu?.rawValue ?? "Invoicing")
        } detail: {
            // right detail pane
            Group {
                if let menu = selectedMenu {
                    switch menu {
                    case .invoicingQueue:
                        if let order = viewModel.selectedWorkOrder {
                            billingEstimationDetailPane(order)
                        } else {
                            EmptyStateView(
                                icon: "doc.text",
                                title: "No Work Order Selected",
                                message: "Select a completed commercial dispatch to compile client billing invoice."
                            )
                        }

                    case .approvedExpenses:
                        approvedExpensesDetailPane

                    case .revenueTelemetry:
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 56))
                                .foregroundColor(Color.accentBlue)
                            Text("Swift Charts Financial Telemetry")
                                .font(.appTitle)
                            Text("Interactive revenue telemetry charts will be configured in Phase 12.")
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
        .task {
            await viewModel.loadBillingData()
        }
    }


    // MARK: - Column 2: Content Lists

    private var invoicingQueueContentList: some View {
        List(viewModel.workOrders, selection: $viewModel.selectedWorkOrder) { order in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(order.workOrderNumber)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandNavy)

                    Spacer()

                    StatusBadge(status: order.status.toStatusType)
                }

                Text(order.title)
                    .font(.appSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(order.facility?.facilityName ?? "Commercial Client")
                    .font(.appCaption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .tag(order)
            .onTapGesture {
                viewModel.selectWorkOrder(order)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadBillingData()
        }
    }

    private var approvedExpensesContentList: some View {
        List(viewModel.approvedExpenses) { claim in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(claim.vendorName)
                        .font(.appHeadline)
                    Spacer()
                    Text(claim.formattedAmount)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.statusGreen)
                }
                HStack {
                    Text("Approved by Supervisor")
                        .font(.caption2)
                        .foregroundColor(Color.statusGreen)
                    Spacer()
                    Text(claim.receiptNumber ?? "INV-VERIFIED")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }

    private var telemetryPlaceholderList: some View {
        List {
            Text("Monthly Facility Revenue")
            Text("Parts Margin vs Wholesale Cost")
            Text("Labor Hours Utilization")
        }
    }


    // MARK: - Column 3: Billing Estimation Detail Pane

    private func billingEstimationDetailPane(_ order: WorkOrder) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // top header card
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentInvoiceNumber)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.brandNavy)

                        Text(order.title)
                            .font(.appHeadline)

                        Text(order.facility?.facilityName ?? "Commercial Facility")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(viewModel.invoiceStatus.label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.statusGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.statusGreen.opacity(0.14))
                        .clipShape(Capsule())
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 1. labor hours calculation card with rate controls
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Billable Labor Hours", systemImage: "clock.badge.checkmark.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Text(viewModel.formattedLaborSubtotal)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.brandNavy)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Verified Shift Hours")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f hours", viewModel.laborHours))
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Hourly Contract Rate")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            Text(String(format: "$%.2f / hr", viewModel.hourlyRate))
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }

                    // interactive labor rate and hours controls
                    VStack(spacing: 8) {
                        Stepper(value: $viewModel.hourlyRate, in: 65.0...150.0, step: 5.0) {
                            HStack {
                                Text("Labor Rate:")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "$%.2f / hr", viewModel.hourlyRate))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.brandNavy)
                            }
                        }

                        Stepper(value: $viewModel.laborHours, in: 0.5...40.0, step: 0.5) {
                            HStack {
                                Text("Labor Hours:")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f hrs", viewModel.laborHours))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.brandNavy)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 2. parts & markup calculation card (with interactive slider)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Emergency Parts & Contract Markup", systemImage: "wrench.and.screwdriver.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Text(viewModel.formattedPartsWithMarkup)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.brandNavy)
                    }

                    Divider()

                    HStack {
                        Text("Wholesale Parts Cost")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedPartsSubtotal)
                            .font(.system(size: 14, weight: .medium))
                    }

                    // interactive markup slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Parts Markup Percentage")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("+\(Int(viewModel.partsMarkupPercent))% (+\(viewModel.formattedMarkupAmount))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.statusGreen)
                        }

                        Slider(value: $viewModel.partsMarkupPercent, in: 15.0...45.0, step: 1.0)
                            .tint(Color.statusGreen)

                        HStack {
                            Text("15% (Standard)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("45% (Critical Emergency)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 3. equipment fee & taxes card
                VStack(alignment: .leading, spacing: 10) {
                    Label("Surcharges & Sales Tax", systemImage: "percent")
                        .font(.appHeadline)
                        .foregroundColor(Color.brandNavy)

                    Divider()

                    HStack {
                        Text("Fleet Equipment Surcharge")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedEquipmentFee)
                            .font(.system(size: 14, weight: .medium))
                    }

                    HStack {
                        Text("State Sales Tax (8.0%)")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedTaxAmount)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 4. exportable official invoice summary card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Commercial Invoice Preview", systemImage: "doc.plaintext.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Text("Net 30")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .cornerRadius(4)
                    }

                    Divider()

                    // formal paper ticket preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHIRL DISPATCH HVAC SOLUTIONS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.brandNavy)

                        Text("Invoice #: \(viewModel.currentInvoiceNumber)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))

                        Text("Client: \(order.facility?.facilityName ?? "Commercial Site")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Divider()

                        HStack {
                            Text("1. Certified HVAC Labor")
                                .font(.system(size: 12))
                            Spacer()
                            Text(viewModel.formattedLaborSubtotal)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }

                        HStack {
                            Text("2. Materials (Markup \(Int(viewModel.partsMarkupPercent))%)")
                                .font(.system(size: 12))
                            Spacer()
                            Text(viewModel.formattedPartsWithMarkup)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }

                        HStack {
                            Text("3. Fleet Equipment Fee")
                                .font(.system(size: 12))
                            Spacer()
                            Text(viewModel.formattedEquipmentFee)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }

                        HStack {
                            Text("4. State Sales Tax (8%)")
                                .font(.system(size: 12))
                            Spacer()
                            Text(viewModel.formattedTaxAmount)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }

                        Divider()

                        HStack {
                            Text("TOTAL BALANCE DUE")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                            Spacer()
                            Text(viewModel.formattedGrandTotal)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.brandNavy)
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    // action buttons: share export & issue to client
                    HStack(spacing: 12) {
                        ShareLink(item: viewModel.invoiceExportText) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Export")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .foregroundColor(Color.brandNavy)
                            .cornerRadius(8)
                        }

                        Button(action: {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            Task {
                                await viewModel.issueInvoiceToClient()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Issue to Client")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.brandNavy)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var approvedExpensesDetailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Approved Field Parts Ledger")
                    .font(.appTitle)

                Text("All emergency supply receipts verified by operations supervisor, ready for client billing markup.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)

                ForEach(viewModel.approvedExpenses) { claim in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(claim.vendorName)
                                .font(.appHeadline)
                            Spacer()
                            Text(claim.formattedAmount)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.statusGreen)
                        }

                        Text("Ticket: \(claim.receiptNumber ?? "INV-APPROVED")")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}


struct ClerkCompactView: View {
    @Bindable var authVM: AuthViewModel
    @State private var viewModel = BillingViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                List(viewModel.workOrders) { order in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(order.workOrderNumber)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                            Spacer()
                            StatusBadge(status: order.status.toStatusType)
                        }
                        Text(order.title)
                            .font(.appHeadline)
                        Text(order.facility?.facilityName ?? "Facility")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Invoicing Queue")
            }
            .tabItem {
                Label("Invoicing", systemImage: "doc.text.fill")
            }
            .tag(0)

            NavigationStack {
                List(viewModel.approvedExpenses) { claim in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(claim.vendorName)
                                .font(.appHeadline)
                            Spacer()
                            Text(claim.formattedAmount)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.statusGreen)
                        }
                        Text(claim.receiptNumber ?? "INV-VERIFIED")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Approved Claims")
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
        .task {
            await viewModel.loadBillingData()
        }
    }
}
