//
//  WorkOrderListView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-18.
//

import SwiftUI
import UIKit

struct WorkOrderListView: View {
    var authVM: AuthViewModel? = nil
    @State private var viewModel = WorkOrdersViewModel()
    @State private var offlineManager = OfflineModeManager.shared
    @State private var historyPage: Int = 1
    private let historyPageSize = 5

    private var totalHistoryPages: Int {
        viewModel.totalHistoryPages(pageSize: historyPageSize)
    }

    private var paginatedHistory: [WorkOrder] {
        viewModel.paginatedHistory(page: historyPage, pageSize: historyPageSize)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // show plant room offline banner when engaged
                if offlineManager.isPlantRoomOffline || viewModel.isOffline {
                    OfflineBanner(
                        isOffline: true,
                        pendingCount: offlineManager.pendingSyncCount
                    ) {
                        Task {
                            await offlineManager.syncPendingChanges()
                            await viewModel.loadWorkOrders()
                        }
                    }
                }

                if viewModel.isLoading && viewModel.workOrders.isEmpty {
                    Spacer()
                    ProgressView("Loading dispatches...")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Dispatches")
            .task {
                if viewModel.workOrders.isEmpty {
                    await viewModel.loadWorkOrders()
                }
            }
        }
    }

    // main dashboard content
    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Shift pulse & greeting header
                greetingCard

                // 2. Operational metrics tiles row
                operationalMetricsRow

                // 3. Current Active Dispatch (Hero Card)
                currentDispatchSection

                // 4. Quick Action Tools Hub
                quickActionsSection

                // 5. Completed Dispatch History (participated)
                completedHistorySection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            await viewModel.loadWorkOrders()
        }
        .onChange(of: viewModel.completedHistory.count) { _, _ in
            if historyPage > totalHistoryPages {
                historyPage = totalHistoryPages
            }
        }
    }

    // greeting and pulse summary card
    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(greeting), \(authVM?.currentUser?.fullName ?? "Field Technician")")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Commercial Field Operations")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Duty status pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(dutyStatusColor)
                        .frame(width: 8, height: 8)

                    Text(dutyStatusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(dutyStatusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(dutyStatusColor.opacity(0.12))
                .clipShape(Capsule())
            }

            // Quick status summary row
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption2)
                        .foregroundColor(Color.brandNavy)
                    Text(viewModel.currentDispatch != nil ? "1 Active Dispatch" : "0 Active Dispatches")
                        .font(.appCaption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Color.statusGreen)
                    Text("\(viewModel.countsByFilter?.completed ?? viewModel.completedHistory.count) Completed")
                        .font(.appCaption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: offlineManager.isPlantRoomOffline ? "antenna.radiowaves.left.and.right.slash" : "icloud.fill")
                        .font(.caption2)
                        .foregroundColor(offlineManager.isPlantRoomOffline ? Color.statusAmber : Color.accentBlue)
                    Text(offlineManager.isPlantRoomOffline ? "Offline" : "Synced")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(offlineManager.isPlantRoomOffline ? Color.statusAmber : Color.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.surfaceBorder.opacity(0.6), lineWidth: 1)
        )
    }

    private var dutyStatusColor: Color {
        if let order = viewModel.currentDispatch {
            switch order.status {
            case .onSiteActive:
                return Color.statusGreen
            case .enRoute:
                return Color.accentBlue
            case .unacknowledgedBreak, .awaitingPartsApproval:
                return Color.statusAmber
            default:
                return Color.brandNavy
            }
        }
        return Color(hex: "607D8B")
    }

    private var dutyStatusText: String {
        if let order = viewModel.currentDispatch {
            switch order.status {
            case .onSiteActive:
                return "ON SITE"
            case .enRoute:
                return "EN ROUTE"
            case .unacknowledgedBreak:
                return "ON BREAK"
            case .awaitingPartsApproval:
                return "AWAITING PARTS"
            case .dispatched:
                return "ASSIGNED"
            default:
                return order.status.label.uppercased()
            }
        }
        return "STANDBY"
    }

    // 3 unclickable horizontal operational metric tiles
    private var operationalMetricsRow: some View {
        HStack(spacing: 10) {
            metricTile(
                icon: "clock.fill",
                iconColor: Color.brandNavy,
                value: todayHoursText,
                title: "TODAY'S SHIFT"
            )

            metricTile(
                icon: "person.badge.shield.checkmark.fill",
                iconColor: dutyStatusColor,
                value: dutyStatusText,
                title: "DUTY STATUS"
            )

            metricTile(
                icon: "bolt.shield.fill",
                iconColor: prioritySlaColor,
                value: prioritySlaText,
                title: "PRIORITY SLA"
            )
        }
    }

    private func metricTile(icon: String, iconColor: Color, value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.surfaceBorder.opacity(0.6), lineWidth: 1)
        )
    }

    private var todayHoursText: String {
        ShiftWidgetSnapshot.load().formattedTodayHours
    }

    private var prioritySlaText: String {
        if let order = viewModel.currentDispatch {
            return order.isEmergency ? "2h Emergency" : order.priority.title
        }
        return "Standby"
    }

    private var prioritySlaColor: Color {
        if let order = viewModel.currentDispatch {
            return order.isEmergency ? Color.statusRed : Color.brandNavy
        }
        return Color(hex: "607D8B")
    }

    // current active dispatch section
    private var currentDispatchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Current Active Dispatch")
                    .font(.appSubheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.currentDispatch != nil {
                    Text("TAP CARD FOR DETAILS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.accentBlue)
                        .tracking(0.5)
                }
            }

            if let order = viewModel.currentDispatch {
                // Hero Active Dispatch Card
                NavigationLink(destination: WorkOrderDetailView(order: order, viewModel: viewModel)) {
                    heroDispatchCard(for: order)
                }
                .buttonStyle(.plain)

                // Inline quick action shortcuts for this dispatch
                HStack(spacing: 10) {
                    if let fac = order.facility {
                        Button(action: {
                            openMaps(facility: fac)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "location.fill")
                                    .font(.caption.bold())
                                Text("Directions")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentBlue.opacity(0.12))
                            .foregroundColor(Color.accentBlue)
                            .cornerRadius(8)
                        }
                    }

                    if let phone = order.facility?.contactPhone, !phone.isEmpty {
                        Button(action: {
                            dialPhone(phone)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "phone.fill")
                                    .font(.caption.bold())
                                Text("Call Site")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.statusGreen.opacity(0.12))
                            .foregroundColor(Color.statusGreen)
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                // Standby Card
                standbyHeroCard
            }
        }
    }

    private func heroDispatchCard(for order: WorkOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: order number, priority & status
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.brandNavy)

                    Text(order.workOrderNumber)
                        .font(.appMonoHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandNavy)
                }

                Spacer()

                PriorityBadge(priority: order.priority.toPriorityLevel)
                StatusBadge(status: order.status.toStatusType)
            }

            // Title
            Text(order.title)
                .font(.appHeadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Description
            if !order.description.isEmpty {
                Text(order.description)
                    .font(.appCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Facility & Address
            if let facility = order.facility {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.accentBlue)

                        Text(facility.displayName)
                            .font(.appSubheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(facility.address)
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            // Footer with time & tap prompt
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(formatScheduledTime(order.scheduledStartTime))
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                if order.isEmergency {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.caption2)
                            .foregroundColor(Color.statusRed)
                        Text("Emergency SLA")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.statusRed)
                    }
                    .padding(.leading, 8)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("View Dispatch")
                        .font(.caption.bold())
                        .foregroundColor(Color.brandNavy)
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(Color.brandNavy)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(order.isEmergency ? Color.statusRed.opacity(0.4) : Color.brandNavy.opacity(0.3), lineWidth: order.isEmergency ? 1.5 : 1)
        )
    }

    private var standbyHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "607D8B").opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "455A64"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("No Active Dispatches Scheduled")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("You are currently on standby for dispatch assignments.")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack {
                Text("Any jobs assigned by your supervisor will appear here.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    Task {
                        await viewModel.loadWorkOrders()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2.bold())
                        Text("Refresh")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brandNavy.opacity(0.10))
                    .foregroundColor(Color.brandNavy)
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.surfaceBorder, lineWidth: 1)
        )
    }

    // quick actions section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Tools")
                .font(.appSubheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // 1. Site Navigation
                Button(action: {
                    if let fac = viewModel.currentDispatch?.facility {
                        openMaps(facility: fac)
                    }
                }) {
                    quickActionTile(
                        icon: "location.north.circle.fill",
                        title: "Navigation",
                        subtitle: viewModel.currentDispatch?.facility != nil ? "Apple Maps" : "No site",
                        isEnabled: viewModel.currentDispatch?.facility != nil
                    )
                }
                .disabled(viewModel.currentDispatch?.facility == nil)

                // 2. Call Contact
                Button(action: {
                    if let phone = viewModel.currentDispatch?.facility?.contactPhone, !phone.isEmpty {
                        dialPhone(phone)
                    }
                }) {
                    quickActionTile(
                        icon: "phone.circle.fill",
                        title: "Site Contact",
                        subtitle: viewModel.currentDispatch?.facility?.contactPersonName ?? "Unassigned",
                        isEnabled: !(viewModel.currentDispatch?.facility?.contactPhone ?? "").isEmpty
                    )
                }
                .disabled((viewModel.currentDispatch?.facility?.contactPhone ?? "").isEmpty)

                // 3. Refresh Schedule
                Button(action: {
                    Task {
                        await viewModel.loadWorkOrders()
                    }
                }) {
                    quickActionTile(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Refresh",
                        subtitle: "Sync latest",
                        isEnabled: true
                    )
                }
            }
        }
    }

    private func quickActionTile(icon: String, title: String, subtitle: String, isEnabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isEnabled ? Color.brandNavy : Color.secondary.opacity(0.4))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isEnabled ? .primary : .secondary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.surfaceBorder.opacity(0.7), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
    }

    // completed dispatch history section with pagination (5 cards per page)
    private var completedHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Completed Dispatch History")
                    .font(.appSubheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(viewModel.countsByFilter?.completed ?? viewModel.completedHistory.count) completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.completedHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)

                    Text("No Completed Dispatches Yet")
                        .font(.appSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Dispatches you have completed will appear here for historical reference.")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.surfaceBorder, lineWidth: 1)
                )
            } else {
                ForEach(paginatedHistory) { order in
                    NavigationLink(destination: WorkOrderDetailView(order: order, viewModel: viewModel)) {
                        WorkOrderCardView(order: order)
                    }
                    .buttonStyle(.plain)
                }

                // pagination controls (5 cards per page)
                if totalHistoryPages > 1 {
                    HStack {
                        Button(action: {
                            if historyPage > 1 {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    historyPage -= 1
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Previous")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(historyPage > 1 ? Color.brandNavy.opacity(0.10) : Color.secondary.opacity(0.08))
                            .foregroundColor(historyPage > 1 ? Color.brandNavy : Color.secondary.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .disabled(historyPage <= 1)

                        Spacer()

                        Text("Page \(historyPage) of \(totalHistoryPages)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: {
                            if historyPage < totalHistoryPages {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    historyPage += 1
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("Next")
                                    .font(.system(size: 12, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(historyPage < totalHistoryPages ? Color.brandNavy.opacity(0.10) : Color.secondary.opacity(0.08))
                            .foregroundColor(historyPage < totalHistoryPages ? Color.brandNavy : Color.secondary.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .disabled(historyPage >= totalHistoryPages)
                    }
                    .padding(.top, 6)
                }
            }
        }
    }

    // map launcher
    private func openMaps(facility: Facility?) {
        guard let fac = facility else { return }
        let lat = fac.latitude
        let lng = fac.longitude
        let urlString = "maps://?daddr=\(lat),\(lng)&dirflg=d"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webUrl = URL(string: "https://maps.apple.com/?daddr=\(lat),\(lng)") {
            UIApplication.shared.open(webUrl)
        }
    }

    // phone dialer
    private func dialPhone(_ phoneNumber: String?) {
        guard let raw = phoneNumber else { return }
        let cleaned = raw.filter("0123456789+".contains)
        guard !cleaned.isEmpty, let url = URL(string: "tel://\(cleaned)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // scheduled timestamp formatter
    private func formatScheduledTime(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        return isoString
    }
}
