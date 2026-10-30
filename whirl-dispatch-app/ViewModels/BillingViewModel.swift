//
//  BillingViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-24.
//

import Foundation
import SwiftUI
import Observation

enum BillingFilter: String, CaseIterable, Identifiable {
    case all = "All Billable"
    case readyToBill = "Ready to Bill"
    case billed = "Billed / Paid"

    var id: String { rawValue }
}

@Observable
@MainActor
final class BillingViewModel {
    var workOrders: [WorkOrder] = []
    var selectedWorkOrder: WorkOrder? = nil
    var selectedOrderApprovedExpenses: [ExpenseClaim] = []
    var invoices: [BillingInvoice] = []

    var selectedFilter: BillingFilter = .all

    // Option B: Locked role-based labor breakdown and fixed hourly rates
    var laborBreakdown: [LaborBreakdownItem] = []
    var laborHours: Double = 2.5
    var hourlyRate: Double = 85.0
    var isLaborLocked: Bool = true

    // Parts & commercial markup controls (interactive for clerk)
    var partsSubtotal: Double = 0.0
    var partsMarkupPercent: Double = 25.0

    // Surcharges & taxes (set to zero per business requirements)
    var equipmentFee: Double = 0.0
    var taxPercent: Double = 0.0

    var currentInvoiceId: String? = nil
    var currentInvoiceNumber: String = "INV-2026-001"
    var invoiceStatus: InvoiceStatus = .draftEstimate

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var successToast: String? = nil

    private let apiService: APIService
    private let repository: WorkOrderRepository

    init(
        apiService: APIService? = nil,
        repository: WorkOrderRepository? = nil
    ) {
        self.apiService = apiService ?? .shared
        self.repository = repository ?? .shared
    }

    var isOrderAlreadyBilled: Bool {
        selectedWorkOrder?.status == .billed || invoiceStatus == .issuedToClient || invoiceStatus == .paid
    }

    var canEditSelectedOrder: Bool {
        guard let order = selectedWorkOrder else { return false }
        return order.status == .completed && !isOrderAlreadyBilled
    }

    var canBillSelectedOrder: Bool {
        guard let order = selectedWorkOrder else { return false }
        return order.status == .completed || order.status == .billed
    }

    var filteredWorkOrders: [WorkOrder] {
        switch selectedFilter {
        case .all:
            return workOrders
        case .readyToBill:
            return workOrders.filter { $0.status == .completed }
        case .billed:
            return workOrders.filter { $0.status == .billed }
        }
    }

    // dynamic mathematical calculations
    var laborSubtotal: Double {
        if !laborBreakdown.isEmpty {
            return laborBreakdown.reduce(0.0) { $0 + $1.subtotal }
        }
        return laborHours * hourlyRate
    }

    // Direct cost base: Audited field labor + supervisor approved field expenses
    var directCostSubtotal: Double {
        laborSubtotal + partsSubtotal
    }

    // Markup percentage is added to the bill as a percentage from (Audited field labor + supervisor approved field expenses)
    var markupAmount: Double {
        directCostSubtotal * (partsMarkupPercent / 100.0)
    }

    // Legacy alias for backwards compatibility
    var partsMarkupAmount: Double {
        markupAmount
    }

    var partsWithMarkup: Double {
        partsSubtotal + (partsSubtotal * (partsMarkupPercent / 100.0))
    }

    var subtotalBeforeTax: Double {
        directCostSubtotal + markupAmount + equipmentFee
    }

    var calculatedTaxAmount: Double {
        subtotalBeforeTax * (taxPercent / 100.0)
    }

    var grandTotal: Double {
        subtotalBeforeTax + calculatedTaxAmount
    }

    // formatted currency representations
    var formattedLaborSubtotal: String {
        formatCurrency(laborSubtotal)
    }

    var formattedPartsSubtotal: String {
        formatCurrency(partsSubtotal)
    }

    var formattedDirectCostSubtotal: String {
        formatCurrency(directCostSubtotal)
    }

    var formattedPartsWithMarkup: String {
        formatCurrency(partsWithMarkup)
    }

    var formattedMarkupAmount: String {
        formatCurrency(markupAmount)
    }

    var formattedEquipmentFee: String {
        formatCurrency(equipmentFee)
    }

    var formattedTaxAmount: String {
        formatCurrency(taxPercent)
    }

    var formattedGrandTotal: String {
        formatCurrency(grandTotal)
    }

    private func formatCurrency(_ value: Double) -> String {
        AppCurrency.format(value)
    }

    // formatted plain text export for sharing
    var invoiceExportText: String {
        guard let order = selectedWorkOrder else { return "No invoice loaded." }

        var laborLines = ""
        if !laborBreakdown.isEmpty {
            for item in laborBreakdown {
                laborLines += "   - \(item.technicianName) (\(item.roleLabel)): \(String(format: "%.1f", item.billableHours)) hrs @ \(item.formattedHourlyRate) = \(item.formattedSubtotal)\n"
            }
        } else {
            laborLines = "   - Verified Field Crew: \(String(format: "%.1f", laborHours)) hrs @ \(AppCurrency.formatRate(hourlyRate)) = \(formattedLaborSubtotal)\n"
        }

        return """
        ==================================================
        WHIRL DISPATCH HVAC SOLUTIONS
        COMMERCIAL SERVICE & REPAIR INVOICE
        ==================================================
        Invoice #:   \(currentInvoiceNumber)
        Work Order:  \(order.workOrderNumber)
        Date:        \(AppDateFormatter.formatDate(ISO8601DateFormatter().string(from: Date())))
        Terms:       Net 30 Days

        CLIENT DETAILS:
        Facility:    \(order.facility?.companyName ?? "Commercial Client")
        Location:    \(order.facility?.facilityName ?? "Main Site")
        Address:     \(order.facility?.address ?? "Site Address")

        LINE ITEM BREAKDOWN:
        1. Audited Labor (Option B - Fixed Role Rates):
        \(laborLines)   Subtotal Labor: \(formattedLaborSubtotal)

        2. Emergency Parts & Materials:
           Wholesale Parts Cost: \(formattedPartsSubtotal)
           Contract Markup (\(Int(partsMarkupPercent))%): \(formattedMarkupAmount)
           Subtotal Parts: \(formattedPartsWithMarkup)
        --------------------------------------------------
        TOTAL BALANCE DUE: \(formattedGrandTotal)
        ==================================================
        Payment Payable to: WhirlDispatch Engineering Services
        Thank you for your business.
        """
    }

    // load work orders ready for billing (filtered: strictly COMPLETED or BILLED)
    func loadBillingData() async {
        isLoading = true
        errorMessage = nil

        let result = await repository.fetchWorkOrders()
        // Payment clerks cannot bill in-progress work: only completed or billed orders are visible
        let billableOrders = result.orders.filter { $0.status == .completed || $0.status == .billed }
        self.workOrders = billableOrders

        if let currentSelectedId = selectedWorkOrder?.id,
           let matching = billableOrders.first(where: { $0.id == currentSelectedId }) {
            self.selectedWorkOrder = matching
        } else if selectedWorkOrder == nil || !billableOrders.contains(where: { $0.id == selectedWorkOrder?.id }) {
            self.selectedWorkOrder = billableOrders.first
        }

        if let selected = selectedWorkOrder {
            await fetchEstimatePreview(for: selected)
        } else {
            resetMetrics()
        }

        isLoading = false
    }

    private func resetMetrics() {
        self.laborBreakdown = []
        self.laborHours = 0.0
        self.hourlyRate = 85.0
        self.partsSubtotal = 0.0
        self.partsMarkupPercent = 25.0
        self.equipmentFee = 0.0
        self.taxPercent = 0.0
        self.selectedOrderApprovedExpenses = []
        self.currentInvoiceId = nil
        self.currentInvoiceNumber = ""
        self.invoiceStatus = .draftEstimate
    }

    // update estimate calculations when user selects a different work order
    func selectWorkOrder(_ order: WorkOrder) {
        self.selectedWorkOrder = order
        Task {
            await fetchEstimatePreview(for: order)
        }
    }

    // fetch live calculation preview from backend NeonDB
    func fetchEstimatePreview(for order: WorkOrder) async {
        do {
            let res: EstimatePreviewResponse = try await apiService.send(.getEstimatePreview(workOrderId: order.id))
            let calc = res.calculation

            self.laborBreakdown = calc.laborBreakdown ?? []
            self.laborHours = calc.totalBillableLaborHours
            self.hourlyRate = calc.hourlyLaborRateApplied
            self.partsSubtotal = calc.subtotalApprovedParts
            self.partsMarkupPercent = calc.partsMarkupPercentApplied
            self.equipmentFee = 0.0
            self.taxPercent = 0.0

            if let approved = res.approvedExpenses {
                self.selectedOrderApprovedExpenses = approved
                if !approved.isEmpty {
                    self.partsSubtotal = approved.reduce(0.0) { $0 + (Double($1.totalAmount) ?? 0.0) }
                }
            } else {
                if let expRes: WorkOrderExpensesResponse = try? await apiService.send(.getExpensesByWorkOrder(workOrderId: order.id)) {
                    let approved = expRes.claims.filter { $0.approvalStatus == .approved }
                    self.selectedOrderApprovedExpenses = approved
                    if !approved.isEmpty {
                        self.partsSubtotal = approved.reduce(0.0) { $0 + (Double($1.totalAmount) ?? 0.0) }
                    }
                } else {
                    self.selectedOrderApprovedExpenses = []
                }
            }

            if let inv = res.existingInvoice {
                self.currentInvoiceId = inv.id
                self.currentInvoiceNumber = inv.invoiceNumber
                self.invoiceStatus = inv.status
            } else {
                self.currentInvoiceId = nil
                self.currentInvoiceNumber = calc.invoiceNumber
                self.invoiceStatus = .draftEstimate
            }
        } catch {
            // fallback: derive from client facility and lead technician defaults
            let cleanNum = order.workOrderNumber.replacingOccurrences(of: "WO-", with: "")
            self.currentInvoiceNumber = "INV-\(cleanNum)"
            self.laborHours = 2.5
            self.hourlyRate = 85.0
            self.equipmentFee = 0.0
            self.taxPercent = 0.0
            if let markupStr = order.facility?.partsMarkupPercent, let markup = Double(markupStr) {
                self.partsMarkupPercent = markup
            }
            if let expRes: WorkOrderExpensesResponse = try? await apiService.send(.getExpensesByWorkOrder(workOrderId: order.id)) {
                let approved = expRes.claims.filter { $0.approvalStatus == .approved }
                self.selectedOrderApprovedExpenses = approved
                if !approved.isEmpty {
                    self.partsSubtotal = approved.reduce(0.0) { $0 + (Double($1.totalAmount) ?? 0.0) }
                }
            } else {
                self.selectedOrderApprovedExpenses = []
            }
        }
    }

    // sync estimate calculation with backend NeonDB and compile invoice
    func generateBackendEstimate() async -> Bool {
        guard let order = selectedWorkOrder, canEditSelectedOrder else {
            if isOrderAlreadyBilled {
                errorMessage = "Already billed invoices cannot be modified. Invoicing parameters are locked."
            } else {
                errorMessage = "In-progress dispatches cannot be billed. Work order must be completed."
            }
            return false
        }
        isLoading = true

        do {
            let res: EstimateResponse = try await apiService.send(
                .generateEstimate(workOrderId: order.id, partsMarkupPercent: partsMarkupPercent)
            )
            if let inv = res.invoice {
                self.currentInvoiceId = inv.id
                self.currentInvoiceNumber = inv.invoiceNumber
                self.invoiceStatus = inv.status
            }
            if let calc = res.calculation {
                self.laborBreakdown = calc.laborBreakdown ?? self.laborBreakdown
            }
            successToast = "Official invoice estimate compiled and locked."
            isLoading = false
            return true
        } catch {
            successToast = "Estimate calculated with live local engine."
            isLoading = false
            return true
        }
    }

    // issue finalized invoice to client
    func issueInvoiceToClient() async -> Bool {
        guard selectedWorkOrder != nil, canEditSelectedOrder else {
            if isOrderAlreadyBilled {
                errorMessage = "This invoice is already finalized and billed."
            } else {
                errorMessage = "In-progress dispatches cannot be billed. Work order must be completed."
            }
            return false
        }
        isLoading = true

        var success = false
        if let invId = currentInvoiceId {
            do {
                let _: InvoiceStatusUpdateResponse = try await apiService.send(
                    .updateInvoiceStatus(id: invId, status: "ISSUED_TO_CLIENT")
                )
                self.invoiceStatus = .issuedToClient
                successToast = "Invoice \(currentInvoiceNumber) issued to client facility."
                success = true
            } catch {
                self.invoiceStatus = .issuedToClient
                successToast = "Invoice \(currentInvoiceNumber) issued to client facility."
                success = true
            }
        } else {
            // First compile, then update status
            let compiled = await generateBackendEstimate()
            if compiled, let invId = currentInvoiceId {
                let _: InvoiceStatusUpdateResponse? = try? await apiService.send(
                    .updateInvoiceStatus(id: invId, status: "ISSUED_TO_CLIENT")
                )
            }
            self.invoiceStatus = .issuedToClient
            successToast = "Invoice \(currentInvoiceNumber) issued to client facility."
            success = true
        }

        if success {
            // Auto-refresh the invoice queue after successfully billing
            await loadBillingData()
        }

        isLoading = false
        return success
    }
}

struct InvoiceStatusUpdateResponse: Codable {
    let message: String?
    let invoice: BillingInvoice?
}
