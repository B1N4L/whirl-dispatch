//
//  ExpensesView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-23.
//

import SwiftUI

struct ExpensesView: View {
    @State private var viewModel = ExpensesViewModel()
    @State private var offlineManager = OfflineModeManager.shared


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // error banner if any
                if let err = viewModel.errorMessage {
                    ErrorBanner(message: err) {
                        viewModel.errorMessage = nil
                    }
                }

                // success notification
                if let msg = viewModel.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.statusGreen)
                        Text(msg)
                            .font(.appCaption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { viewModel.successMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.statusGreen.opacity(0.12))
                }

                if let dispatch = viewModel.currentDispatch {
                    ScrollView {
                        VStack(spacing: 16) {
                            // active dispatch context header
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(dispatch.workOrderNumber)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.brandNavy.opacity(0.12))
                                            .foregroundColor(Color.brandNavy)
                                            .cornerRadius(4)

                                        Text(dispatch.status.label)
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(dispatch.facility?.facilityName ?? dispatch.title)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 4)

                            // 1. executive financial summary card
                            metricsSummaryCard

                            // 2. filter chips row
                            filterChipsRow

                            // 3. claims ledger list
                            claimsLedgerContent
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await viewModel.loadExpenses()
                    }
                } else {
                    standbyEmptyStateView
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Field Expenses")
            .toolbar {
                if viewModel.currentDispatch != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            viewModel.showNewExpenseSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("New Receipt")
                                    .fontWeight(.semibold)
                            }
                            .font(.appSubheadline)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewExpenseSheet) {
                if let dispatch = viewModel.currentDispatch {
                    NewExpenseSheet(
                        workOrderId: dispatch.id
                    ) { woId, vendor, inv, price, qty, desc, cat in
                        await viewModel.submitExpense(
                            workOrderId: woId,
                            vendorName: vendor,
                            receiptNumber: inv,
                            unitPrice: price,
                            quantity: qty,
                            partDescription: desc,
                            category: cat
                        )
                    }
                }
            }
            .task {
                await viewModel.loadExpenses()
            }
        }
    }


    // MARK: - Subviews

    // executive financial summary card
    private var metricsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Claimed")
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(viewModel.formattedTotalClaimed)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Approved Payout")
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(viewModel.formattedTotalApproved)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.statusGreen)
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 16) {
                summaryCounter(label: "Pending", count: viewModel.pendingCount, color: Color.statusAmber, icon: "hourglass")
                Spacer()
                summaryCounter(label: "Approved", count: viewModel.approvedCount, color: Color.statusGreen, icon: "checkmark.seal.fill")
                Spacer()
                summaryCounter(label: "Rejected", count: viewModel.rejectedCount, color: Color.statusRed, icon: "xmark.seal.fill")
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.brandNavy, Color.brandNavy.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private func summaryCounter(label: String, count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text("\(count) \(label)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }


    // standby empty state view when technician has no active dispatch
    private var standbyEmptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "607D8B").opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "455A64"))
            }

            VStack(spacing: 6) {
                Text("No Active Dispatch")
                    .font(.appHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("You are not currently dispatched to any work orders.\nField expense receipts can only be filed during an active job assignment.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                Task {
                    await viewModel.loadExpenses()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text("Refresh Dispatches")
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.brandNavy.opacity(0.10))
                .foregroundColor(Color.brandNavy)
                .cornerRadius(8)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // filter chips row
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All Claims",
                    count: viewModel.claims.count,
                    isSelected: viewModel.selectedFilter == .all
                ) {
                    viewModel.selectedFilter = .all
                }

                FilterChip(
                    title: "Pending",
                    count: viewModel.pendingCount,
                    isSelected: viewModel.selectedFilter == .pending
                ) {
                    viewModel.selectedFilter = .pending
                }

                FilterChip(
                    title: "Approved",
                    count: viewModel.approvedCount,
                    isSelected: viewModel.selectedFilter == .approved
                ) {
                    viewModel.selectedFilter = .approved
                }

                FilterChip(
                    title: "Rejected",
                    count: viewModel.rejectedCount,
                    isSelected: viewModel.selectedFilter == .rejected
                ) {
                    viewModel.selectedFilter = .rejected
                }
            }
            .padding(.vertical, 2)
        }
    }


    // claims ledger content
    @ViewBuilder
    private var claimsLedgerContent: some View {
        if viewModel.isLoading && viewModel.claims.isEmpty {
            ProgressView("Loading field receipts...")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if viewModel.filteredClaims.isEmpty {
            EmptyStateView(
                icon: "receipt",
                title: "No Expense Claims",
                message: viewModel.selectedFilter == .all
                    ? "No emergency supply house receipts logged for this dispatch yet."
                    : "No claims matching '\(viewModel.selectedFilter.rawValue)' status.",
                actionTitle: "Log Emergency Part"
            ) {
                viewModel.showNewExpenseSheet = true
            }
            .padding(.top, 20)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredClaims) { claim in
                    expenseClaimCard(claim)
                }
            }
        }
    }


    // individual claim card
    private func expenseClaimCard(_ claim: ExpenseClaim) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // header row: vendor name and approval status badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(claim.vendorName)
                        .font(.appHeadline)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(claim.receiptNumber ?? "No Receipt #")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .cornerRadius(4)

                        if claim.receiptCapturedAt != nil {
                            Text(claim.formattedCapturedDate)
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // approval badge
                approvalStatusBadge(claim.approvalStatus)
            }

            // optical review indicator if threshold exceeded
            if claim.isThresholdExceeded == true {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.statusAmber)
                    Text("Optical Supervisor Review Flagged (>LKR 250)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.statusAmber)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.statusAmber.opacity(0.12))
                .cornerRadius(6)
            }

            // items breakdown
            if let items = claim.items, !items.isEmpty {
                VStack(spacing: 6) {
                    ForEach(items) { item in
                        HStack {
                            Text("\(item.quantity)x \(item.partDescription)")
                                .font(.appSubheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Text(item.formattedTotalPrice)
                                .font(.appSubheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(8)
            }

            // supervisor rejection callout banner
            if claim.approvalStatus == .rejected {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.statusRed)
                        Text("Supervisor Rejection Reason:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.statusRed)
                    }

                    Text(claim.rejectionReason ?? "Claim flagged during supervisor audit. Please verify invoice or re-submit.")
                        .font(.appCaption)
                        .foregroundColor(.primary)
                        .padding(.leading, 18)
                }
                .padding(10)
                .background(Color.statusRed.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.statusRed.opacity(0.3), lineWidth: 1)
                )
            }

            Divider()

            // total row
            HStack {
                Text("Total Claimed")
                    .font(.appCaption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(claim.formattedAmount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandNavy)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }


    // badge component for approval status
    private func approvalStatusBadge(_ status: ExpenseApprovalStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(status.label)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.14))
        .foregroundColor(status.color)
        .clipShape(Capsule())
    }
}


#Preview {
    ExpensesView()
}
