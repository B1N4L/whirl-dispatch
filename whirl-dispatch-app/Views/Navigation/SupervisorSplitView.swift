//
//  SupervisorSplitView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-16.
//

import SwiftUI
import UIKit

struct SupervisorSplitView: View {
    @Bindable var authVM: AuthViewModel
    @State private var viewModel = SupervisorViewModel()
    @State private var selectedMenu: SupervisorMenu? = .activeDispatches
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showReassignSheet: Bool = false
    @State private var showRejectSheet: Bool = false
    @State private var rejectionReasonInput: String = ""
    @State private var claimToReject: ExpenseClaim? = nil


    enum SupervisorMenu: String, CaseIterable, Identifiable {
        case activeDispatches = "Active Dispatches"
        case expenseApprovals = "Expense Approvals"
        case teamStatus = "Technician Roster"
        case fleetMap = "Fleet Map"
        case profile = "Supervisor Profile"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .activeDispatches: return "list.bullet.clipboard.fill"
            case .expenseApprovals: return "checkmark.seal.fill"
            case .teamStatus: return "person.3.fill"
            case .fleetMap: return "map.fill"
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
                    case .activeDispatches:
                        dispatchesContentList

                    case .expenseApprovals:
                        expenseApprovalsContentList

                    case .teamStatus:
                        teamRosterContentList

                    case .fleetMap:
                        fleetMapPlaceholderList

                    case .profile:
                        ProfileTabView(authVM: authVM)
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
                    case .activeDispatches:
                        if let order = viewModel.selectedWorkOrder {
                            dispatchDetailPane(order)
                        } else {
                            EmptyStateView(
                                icon: "list.clipboard",
                                title: "No Dispatch Selected",
                                message: "Choose a commercial work order from the list to inspect facility telemetry and assign crew."
                            )
                        }

                    case .expenseApprovals:
                        if let claim = viewModel.selectedExpense {
                            opticalExpenseDetailPane(claim)
                        } else {
                            EmptyStateView(
                                icon: "checkmark.seal",
                                title: "No Expense Selected",
                                message: "Select an emergency field claim from the queue to perform optical audit."
                            )
                        }

                    case .teamStatus:
                        teamRosterDetailPane

                    case .fleetMap:
                        VStack(spacing: 16) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color.accentBlue)
                            Text("Interactive Fleet & Facility Tracker")
                                .font(.appTitle)
                            Text("MapKit streaming GPS coordinates will be configured in Phase 10.")
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
        .task {
            await viewModel.loadSupervisorData()
        }
        .sheet(isPresented: $showReassignSheet) {
            reassignCrewSheet
        }
        .sheet(isPresented: $showRejectSheet) {
            rejectExpenseReasonSheet
        }
    }


    // MARK: - Column 2: Content Lists

    private var dispatchesContentList: some View {
        VStack(spacing: 0) {
            // filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(
                        title: "All",
                        count: viewModel.workOrders.count,
                        isSelected: viewModel.selectedFilter == .all
                    ) {
                        viewModel.selectedFilter = .all
                    }

                    FilterChip(
                        title: "Emergency",
                        count: viewModel.emergencyDispatchesCount,
                        isSelected: viewModel.selectedFilter == .emergency
                    ) {
                        viewModel.selectedFilter = .emergency
                    }

                    FilterChip(
                        title: "Active",
                        count: viewModel.activeOnSiteCount,
                        isSelected: viewModel.selectedFilter == .active
                    ) {
                        viewModel.selectedFilter = .active
                    }

                    FilterChip(
                        title: "Completed",
                        isSelected: viewModel.selectedFilter == .completed
                    ) {
                        viewModel.selectedFilter = .completed
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()

            List(viewModel.filteredWorkOrders, selection: $viewModel.selectedWorkOrder) { order in
                HStack(spacing: 10) {
                    // priority color stripe
                    Rectangle()
                        .fill(order.priority == .criticalEmergency ? Color.statusRed : Color.brandNavy)
                        .frame(width: 4)
                        .cornerRadius(2)

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

                        Text(order.facility?.facilityName ?? "Commercial Plant Room")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .tag(order)
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadSupervisorData()
            }
        }
    }

    private var expenseApprovalsContentList: some View {
        List(viewModel.pendingExpenses, selection: $viewModel.selectedExpense) { claim in
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(claim.vendorName)
                            .font(.appHeadline)
                            .foregroundColor(.primary)

                        Text(claim.receiptNumber ?? "No Receipt #")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(claim.formattedAmount)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.brandNavy)

                        Text(claim.approvalStatus.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(claim.approvalStatus.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(claim.approvalStatus.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if claim.isThresholdExceeded == true {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 10))
                        Text("Optical Inspection Required (>$250)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color.statusAmber)
                }
            }
            .padding(.vertical, 4)
            .tag(claim)
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadSupervisorData()
        }
    }

    private var teamRosterContentList: some View {
        List(viewModel.technicians) { tech in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tech.name)
                        .font(.appHeadline)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: tech.status.iconName)
                            .font(.system(size: 10))
                        Text(tech.status.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(tech.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tech.status.color.opacity(0.12))
                    .clipShape(Capsule())
                }

                Text(tech.roleTitle)
                    .font(.appCaption)
                    .foregroundColor(.secondary)

                if let dispatch = tech.assignedWorkOrderTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.brandNavy)
                        Text(dispatch)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }

    private var fleetMapPlaceholderList: some View {
        List {
            Text("Zone 1: Metro Commercial Center (Chiller 04)")
            Text("Zone 2: Apex Healthcare Tower (Rooftop AHU)")
            Text("Zone 3: North Central Data Center")
        }
    }


    // MARK: - Column 3: Detail Panes

    private func dispatchDetailPane(_ order: WorkOrder) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // top header card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(order.workOrderNumber)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.accentBlue)

                        Spacer()

                        PriorityBadge(priority: order.priority.toPriorityLevel)
                        StatusBadge(status: order.status.toStatusType)
                    }

                    Text(order.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text(order.description)
                        .font(.appBody)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // facility telemetry card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Facility Telemetry & Access", systemImage: "building.2.fill")
                        .font(.appHeadline)
                        .foregroundColor(Color.brandNavy)

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.facility?.facilityName ?? "Facility Info Unavailable")
                                .font(.appHeadline)
                            Text(order.facility?.address ?? "Basement Plant Room B2")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        if let phone = order.facility?.contactPhone {
                            Link(destination: URL(string: "tel:\(phone)")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                    Text("Contact Site")
                                }
                                .font(.appCaption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentBlue.opacity(0.12))
                                .foregroundColor(Color.accentBlue)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // assigned crew card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Assigned Crew & Safety", systemImage: "person.3.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Button("Reassign Crew") {
                            showReassignSheet = true
                        }
                        .font(.appCaption)
                        .fontWeight(.semibold)
                        .buttonStyle(.bordered)
                        .tint(Color.brandNavy)
                    }

                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundColor(Color.statusGreen)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nuwan Silva (Lead Tech)")
                                .font(.appHeadline)
                            Text("Safety Clearance: Plant Room HVAC LOTO Verified")
                                .font(.appCaption)
                                .foregroundColor(Color.statusGreen)
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // scheduled timings
                VStack(alignment: .leading, spacing: 10) {
                    Label("Service Level Agreement (SLA)", systemImage: "clock.badge.exclamationmark.fill")
                        .font(.appHeadline)
                        .foregroundColor(Color.brandNavy)

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Target Arrival")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            Text(order.scheduledStartTime.prefix(16))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Target Wrap-Up")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            Text(order.scheduledEndTime.prefix(16))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
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

    // optical receipt audit detail pane
    private func opticalExpenseDetailPane(_ claim: ExpenseClaim) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // top header card
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(claim.vendorName)
                            .font(.system(size: 24, weight: .bold))

                        HStack(spacing: 8) {
                            Text("Ticket: \(claim.receiptNumber ?? "INV-PENDING")")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)

                            if let dt = claim.receiptCapturedAt {
                                Text("• \(dt.prefix(10))")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(claim.formattedAmount)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.brandNavy)

                        Text(claim.approvalStatus.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(claim.approvalStatus.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(claim.approvalStatus.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // optical receipt simulation ticket
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Optical Purchase Ticket", systemImage: "doc.viewfinder.fill")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(Color.statusGreen)
                        Text("OCR Verified")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.statusGreen)
                    }

                    Divider()

                    // simulated optical ticket container
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHIRL DISPATCH • FIELD PURCHASE AUDIT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("Vendor: \(claim.vendorName)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))

                        Text("GPS Stamp: Lat \(String(format: "%.4f", claim.receiptStoreLatitude ?? 6.9271)), Lng \(String(format: "%.4f", claim.receiptStoreLongitude ?? 79.8612))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text("- - - - - - - - - - - - - - - - - - - - - - - - - - -")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        if let items = claim.items, !items.isEmpty {
                            ForEach(items) { item in
                                HStack {
                                    Text("\(item.quantity)x \(item.partDescription)")
                                        .font(.system(size: 12, design: .monospaced))
                                    Spacer()
                                    Text("$\(item.totalPrice)")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                }
                            }
                        } else {
                            HStack {
                                Text("Emergency HVAC Spare Part")
                                    .font(.system(size: 12, design: .monospaced))
                                Spacer()
                                Text(claim.formattedAmount)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                        }

                        Text("- - - - - - - - - - - - - - - - - - - - - - - - - - -")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        HStack {
                            Text("TOTAL PAID (INC TAX)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                            Spacer()
                            Text(claim.formattedAmount)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // threshold inspection callout
                if claim.isThresholdExceeded == true {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.statusAmber)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Optical Review Threshold Exceeded ($250.00 Limit)")
                                .font(.appSubheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.statusAmber)

                            Text("Verify that the line items match the plant room compressor repairs before approving for billing.")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.statusAmber.opacity(0.1))
                    .cornerRadius(10)
                }

                // rejection reason note if flagged
                if claim.approvalStatus == .rejected {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.seal.fill")
                                .foregroundColor(Color.statusRed)
                            Text("Flagged & Rejected by Supervisor")
                                .font(.appSubheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.statusRed)
                        }

                        Text(claim.rejectionReason ?? "Part not authorized for this dispatch or duplicate receipt.")
                            .font(.appBody)
                            .foregroundColor(.primary)
                    }
                    .padding(14)
                    .background(Color.statusRed.opacity(0.08))
                    .cornerRadius(10)
                }

                // supervisor action controls
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        Button(action: {
                            claimToReject = claim
                            rejectionReasonInput = ""
                            showRejectSheet = true
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Flag / Reject")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.statusRed.opacity(0.12))
                            .foregroundColor(Color.statusRed)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            Task {
                                await viewModel.reviewExpense(claimId: claim.id, status: .approved)
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Approve Expense")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.statusGreen)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var teamRosterDetailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Technician Team Deployment")
                    .font(.appTitle)

                Text("Real-time roster of active technicians deployed across regional plant rooms.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)

                ForEach(viewModel.technicians) { tech in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tech.name)
                                    .font(.appHeadline)
                                Text(tech.roleTitle)
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(tech.status.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(tech.status.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(tech.status.color.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Divider()

                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.secondary)
                            Text(tech.lastSeenText)
                                .font(.appCaption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Link(destination: URL(string: "tel:\(tech.contactNumber)")!) {
                                Image(systemName: "phone.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.statusGreen)
                            }
                        }
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

    private var reassignCrewSheet: some View {
        NavigationStack {
            List(viewModel.technicians) { tech in
                Button(action: {
                    if let wo = viewModel.selectedWorkOrder {
                        viewModel.reassignTechnician(workOrderId: wo.id, techName: tech.name)
                    }
                    showReassignSheet = false
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(tech.name)
                                .font(.appHeadline)
                                .foregroundColor(.primary)
                            Text(tech.roleTitle)
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(tech.status.rawValue)
                            .font(.caption)
                            .foregroundColor(tech.status.color)
                    }
                }
            }
            .navigationTitle("Reassign Dispatch Crew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showReassignSheet = false
                    }
                }
            }
        }
    }

    private var rejectExpenseReasonSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Specify Reason for Rejection")
                    .font(.appHeadline)

                Text("Coursework compliance requires an audit explanation for rejected field expenses.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)

                TextEditor(text: $rejectionReasonInput)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Button("Pre-contract Coverage") {
                        rejectionReasonInput = "Item already covered under facility annual maintenance agreement."
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)

                    Button("Price Discrepancy") {
                        rejectionReasonInput = "Unit price exceeds supply house contracted wholesale rate."
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(action: {
                    if let target = claimToReject {
                        let reason = rejectionReasonInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? "Expense flagged during supervisor optical audit."
                            : rejectionReasonInput.trimmingCharacters(in: .whitespaces)

                        Task {
                            await viewModel.reviewExpense(claimId: target.id, status: .rejected, reason: reason)
                        }
                    }
                    showRejectSheet = false
                }) {
                    Text("Confirm Flag & Rejection")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.statusRed)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(rejectionReasonInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
            .navigationTitle("Flag Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showRejectSheet = false
                    }
                }
            }
        }
    }
}


struct SupervisorCompactView: View {
    @Bindable var authVM: AuthViewModel
    @State private var viewModel = SupervisorViewModel()
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
                .navigationTitle("Dispatches")
            }
            .tabItem {
                Label("Dispatches", systemImage: "list.bullet.clipboard.fill")
            }
            .tag(0)

            NavigationStack {
                List(viewModel.technicians) { tech in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(tech.name)
                                .font(.appHeadline)
                            Text(tech.roleTitle)
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(tech.status.rawValue)
                            .font(.caption2)
                            .foregroundColor(tech.status.color)
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Team Roster")
            }
            .tabItem {
                Label("Team", systemImage: "person.3.fill")
            }
            .tag(1)

            NavigationStack {
                List(viewModel.pendingExpenses) { claim in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(claim.vendorName)
                                .font(.appHeadline)
                            Spacer()
                            Text(claim.formattedAmount)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.brandNavy)
                        }
                        HStack {
                            Text(claim.approvalStatus.label)
                                .font(.caption2)
                                .foregroundColor(claim.approvalStatus.color)
                            Spacer()
                            Text(claim.receiptNumber ?? "No Receipt")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Approvals Queue")
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
        .task {
            await viewModel.loadSupervisorData()
        }
    }
}
