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
    @State private var selectedMenu: ClerkMenu? = .revenueTelemetry
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedProfileSection: ProfileSection = .personalContact


    enum ClerkMenu: String, CaseIterable, Identifiable {
        case revenueTelemetry = "Financial Dashboard"
        case invoicingQueue = "Invoicing Queue"
        case profile = "Clerk Profile"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .revenueTelemetry: return "chart.bar.xaxis"
            case .invoicingQueue: return "doc.text.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }


    var body: some View {
        Group {
            if selectedMenu == .revenueTelemetry {
                // 2-column split view for Financial Dashboard (eliminates middle column)
                NavigationSplitView {
                    sidebarContent
                } detail: {
                    BillingAnalyticsView()
                }
            } else {
                // 3-column split view for Invoicing Queue and Clerk Profile
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebarContent
                } content: {
                    // middle column list
                    Group {
                        if let menu = selectedMenu {
                            switch menu {
                            case .invoicingQueue:
                                invoicingQueueContentList

                            case .profile:
                                ProfileSectionMenuView(authVM: authVM, selectedSection: $selectedProfileSection)

                            case .revenueTelemetry:
                                EmptyView()
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

                            case .profile:
                                ProfileDetailPane(section: selectedProfileSection, authVM: authVM)

                            case .revenueTelemetry:
                                BillingAnalyticsView()
                            }
                        } else {
                            Text("Select an invoice from the list")
                                .font(.appBody)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await viewModel.loadBillingData()
        }
    }


    // MARK: - Column 1: Sidebar Content

    private var sidebarContent: some View {
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
    }


    // MARK: - Column 2: Content Lists

    private var invoicingQueueContentList: some View {
        VStack(spacing: 0) {
            Picker("Filter Queue", selection: $viewModel.selectedFilter) {
                ForEach(BillingFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if viewModel.filteredWorkOrders.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 38))
                        .foregroundColor(Color.brandNavy.opacity(0.35))

                    Text("No Completed Dispatches")
                        .font(.appHeadline)
                        .foregroundColor(.primary)

                    Text("Dispatches currently in progress are hidden from billing until technicians finish on-site work and mark them completed.")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Refresh Queue") {
                        Task {
                            await viewModel.loadBillingData()
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.brandNavy)
                    .padding(.top, 4)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredWorkOrders, selection: $viewModel.selectedWorkOrder) { order in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center) {
                            Text(order.workOrderNumber)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.brandNavy)

                            Spacer()

                            BillingStageBadge(isBilled: order.status == .billed)
                        }

                        Text(order.title)
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        HStack {
                            Text(order.facility?.facilityName ?? "Commercial Client")
                                .font(.appCaption)
                                .foregroundColor(.secondary)

                            Spacer()

                            StatusBadge(status: order.status.toStatusType)
                        }
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
        }
    }


    // MARK: - Column 3: Billing Estimation Detail Pane

    private func billingEstimationDetailPane(_ order: WorkOrder) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Top Toast Alert (if active)
                if let toast = viewModel.successToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.statusGreen)
                        Text(toast)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.statusGreen)
                        Spacer()
                        Button(action: { viewModel.successToast = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.statusGreen.opacity(0.12))
                    .cornerRadius(8)
                }

                // Top Error Alert (if active)
                if let err = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(Color.statusRed)
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.statusRed)
                        Spacer()
                        Button(action: { viewModel.errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.statusRed.opacity(0.12))
                    .cornerRadius(8)
                }

                // Top Invoicing Status Restriction Banners
                if viewModel.isOrderAlreadyBilled {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(Color.statusGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Invoice Finalized & Billed")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.statusGreen)
                            Text("Invoicing parameters are locked and cannot be edited.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.statusGreen.opacity(0.12))
                    .cornerRadius(8)
                } else if !viewModel.canBillSelectedOrder {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.statusAmber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dispatch In Progress (\(order.status.label))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.statusAmber)
                            Text("Invoicing and client issuance are restricted until technicians mark this dispatch as Completed.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.statusAmber.opacity(0.12))
                    .cornerRadius(8)
                }

                // top header card
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(viewModel.currentInvoiceNumber)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.brandNavy)

                            BillingStageBadge(isBilled: order.status == .billed)
                        }

                        Text(order.title)
                            .font(.appHeadline)

                        Text(order.facility?.facilityName ?? "Commercial Facility")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(viewModel.invoiceStatus.label)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.statusGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.statusGreen.opacity(0.14))
                            .clipShape(Capsule())

                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 1. Audited Field Labor (Option B - Fixed Role-Based Rates)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        Label("Audited Field Labor", systemImage: "lock.shield.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Text(viewModel.formattedLaborSubtotal)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.brandNavy)
                    }

                    // System audit badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.statusGreen)
                        Text("Geofence Verified • Fixed Role Rates Locked")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.statusGreen)

                        Spacer()

                        Text("SOX Compliant")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.statusGreen.opacity(0.08))
                    .cornerRadius(6)

                    Text("Labor hours are calculated strictly from verified on-site geofence shifts and bound to fixed technician role rates. Billing clerks cannot modify labor hours or rates.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Divider()

                    // Itemized technician role breakdown
                    if !viewModel.laborBreakdown.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.laborBreakdown) { item in
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(item.technicianName)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(item.roleLabel)
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    item.role == "LEAD_TECHNICIAN"
                                                        ? Color.brandNavy.opacity(0.12)
                                                        : Color.secondary.opacity(0.15)
                                                )
                                                .foregroundColor(
                                                    item.role == "LEAD_TECHNICIAN"
                                                        ? Color.brandNavy
                                                        : Color.primary
                                                )
                                                .cornerRadius(4)
                                        }

                                        Text("\(item.formattedHours) verified @ \(item.formattedHourlyRate)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(item.formattedSubtotal)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.brandNavy)
                                }
                                .padding(10)
                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                        }
                    } else {
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
                                Text("Applied Role Rate")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                                Text(AppCurrency.formatRate(viewModel.hourlyRate))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .padding(10)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }

                    // Total verified labor hours indicator
                    HStack {
                        Text("Total Audited On-Site Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f hrs", viewModel.laborHours))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 2. Supervisor-Approved Field Expenses (Technician parts brief for clerk inspection)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        Label("Supervisor-Approved Field Expenses", systemImage: "checkmark.seal.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Text(viewModel.formattedPartsSubtotal)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.brandNavy)
                    }

                    Text("Wholesale parts and materials logged by field technicians and approved by the supervisor for this dispatch.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Divider()

                    if viewModel.selectedOrderApprovedExpenses.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("No field parts expenses logged for this dispatch.")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.selectedOrderApprovedExpenses) { claim in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(claim.vendorName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Text(claim.formattedAmount)
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.statusGreen)
                                    }

                                    HStack(spacing: 8) {
                                        if let receipt = claim.receiptNumber {
                                            Text("Receipt: \(receipt)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text("Supervisor Approved")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.statusGreen.opacity(0.12))
                                            .foregroundColor(Color.statusGreen)
                                            .cornerRadius(4)
                                    }

                                    if let items = claim.items, !items.isEmpty {
                                        VStack(spacing: 4) {
                                            ForEach(items) { item in
                                                HStack {
                                                    Text("\(item.quantity)x \(item.partDescription)")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Text(item.formattedTotalPrice)
                                                        .font(.system(size: 11, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .padding(8)
                                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(10)
                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // 3. Commercial markup & business profit calculation card (with interactive slider)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Commercial Markup & Business Profit", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Text("+\(viewModel.formattedMarkupAmount)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.statusGreen)
                    }

                    Divider()

                    HStack {
                        Text("Audited Field Labor")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedLaborSubtotal)
                            .font(.system(size: 14, weight: .medium))
                    }

                    HStack {
                        Text("Supervisor Approved Expenses")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedPartsSubtotal)
                            .font(.system(size: 14, weight: .medium))
                    }

                    HStack {
                        Text("Combined Direct Cost Base")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedDirectCostSubtotal)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }

                    HStack {
                        Text("Business Profit Markup")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("+\(viewModel.formattedMarkupAmount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.statusGreen)
                    }

                    // interactive markup slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Markup Percentage")
                                .font(.appSubheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("+\(Int(viewModel.partsMarkupPercent))% (+\(viewModel.formattedMarkupAmount))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.statusGreen)
                        }

                        Slider(value: $viewModel.partsMarkupPercent, in: 0.0...50.0, step: 1.0)
                            .tint(Color.statusGreen)
                            .disabled(!viewModel.canEditSelectedOrder)

                        HStack {
                            Text("0% (Direct Cost)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Spacer()
                            if !viewModel.canEditSelectedOrder {
                                Text("Locked - Finalized at +\(Int(viewModel.partsMarkupPercent))%")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color.statusAmber)
                                Spacer()
                            }
                            Text("50% (Max Margin)")
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

                // 4. exportable official invoice summary card (Surcharges & Sales Tax removed)
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
                            Text("1. Certified Field Labor")
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Text(viewModel.formattedLaborSubtotal)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }

                        if !viewModel.laborBreakdown.isEmpty {
                            ForEach(viewModel.laborBreakdown) { item in
                                HStack {
                                    Text("   - \(item.technicianName) (\(item.roleLabel))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(item.formattedHours) @ \(item.formattedHourlyRate)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        HStack {
                            Text("2. Supervisor Approved Expenses")
                                .font(.system(size: 12))
                            Spacer()
                            Text(viewModel.formattedPartsSubtotal)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }

                        HStack {
                            Text("3. Commercial Markup (+\(Int(viewModel.partsMarkupPercent))%)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.statusGreen)
                            Spacer()
                            Text("+\(viewModel.formattedMarkupAmount)")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.statusGreen)
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

                    // action buttons: compile official invoice, share export & issue to client
                    VStack(spacing: 8) {
                        if viewModel.canEditSelectedOrder {
                            Button(action: {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                Task {
                                    _ = await viewModel.generateBackendEstimate()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    Text("Re-Calculate & Compile Draft")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                .foregroundColor(Color.brandNavy)
                                .cornerRadius(8)
                            }
                        }

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

                            if viewModel.isOrderAlreadyBilled {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Invoice Finalized & Billed")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.statusGreen.opacity(0.18))
                                .foregroundColor(Color.statusGreen)
                                .cornerRadius(8)
                            } else if viewModel.canEditSelectedOrder {
                                Button(action: {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    Task {
                                        _ = await viewModel.issueInvoiceToClient()
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
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                    Text("Awaiting Completion")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.secondary)
                                .cornerRadius(8)
                            }
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
}


struct ClerkCompactView: View {
    @Bindable var authVM: AuthViewModel
    @State private var viewModel = BillingViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                List(viewModel.workOrders) { order in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(order.workOrderNumber)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.brandNavy)
                            Spacer()
                            BillingStageBadge(isBilled: order.status == .billed)
                        }
                        Text(order.title)
                            .font(.appHeadline)
                            .lineLimit(1)
                        HStack {
                            Text(order.facility?.facilityName ?? "Facility")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            Spacer()
                            StatusBadge(status: order.status.toStatusType)
                        }
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
                BillingAnalyticsView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.xaxis")
            }
            .tag(1)

            NavigationStack {
                ProfileTabView(authVM: authVM)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(2)
        }
        .tint(Color.brandNavy)
        .task {
            await viewModel.loadBillingData()
        }
    }
}

struct BillingStageBadge: View {
    let isBilled: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isBilled ? "checkmark.seal.fill" : "clock.badge.checkmark.fill")
                .font(.system(size: 8, weight: .bold))
            Text(isBilled ? "Already Billed" : "About to be Billed")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .foregroundColor(isBilled ? Color.statusGreen : Color.statusAmber)
        .background(
            Capsule()
                .fill(isBilled ? Color.statusGreen.opacity(0.12) : Color.statusAmber.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(isBilled ? Color.statusGreen.opacity(0.28) : Color.statusAmber.opacity(0.28), lineWidth: 0.8)
        )
        .accessibilityLabel(isBilled ? "Billing Status: Already Billed" : "Billing Status: About to be Billed")
    }
}
