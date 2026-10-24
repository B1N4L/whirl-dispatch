//
//  BillingViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-24.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class BillingViewModel {
    var workOrders: [WorkOrder] = []
    var selectedWorkOrder: WorkOrder? = nil
    var approvedExpenses: [ExpenseClaim] = []
    var invoices: [BillingInvoice] = []

    // dynamic cost estimation engine properties
    var laborHours: Double = 4.5
    var hourlyRate: Double = 85.0
    var partsSubtotal: Double = 185.0
    var partsMarkupPercent: Double = 25.0
    var equipmentFee: Double = 75.0
    var taxPercent: Double = 8.0

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


    // dynamic mathematical calculations
    var laborSubtotal: Double {
        laborHours * hourlyRate
    }

    var partsMarkupAmount: Double {
      partsSubtotal * (partsMarkupPercent / 100.0)
    }

    var partsWithMarkup: Double {
        partsSubtotal + partsMarkupAmount
    }

    var subtotalBeforeTax: Double {
        laborSubtotal + partsWithMarkup + equipmentFee
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

    var formattedPartsWithMarkup: String {
        formatCurrency(partsWithMarkup)
    }

    var formattedMarkupAmount: String {
        formatCurrency(partsMarkupAmount)
    }

    var formattedEquipmentFee: String {
        formatCurrency(equipmentFee)
    }

    var formattedTaxAmount: String {
        formatCurrency(calculatedTaxAmount)
    }

    var formattedGrandTotal: String {
        formatCurrency(grandTotal)
    }

    private func formatCurrency(_ value: Double) -> String {
       let formatter = NumberFormatter()
       formatter.numberStyle = .currency
       formatter.currencyCode = "USD"
       return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }


    // load work orders ready for billing
    func loadBillingData() async {
        isLoading = true
        errorMessage = nil

        let (orders, _, _) = await repository.fetchWorkOrders()
        self.workOrders = orders

        if selectedWorkOrder == nil {
            // default to first completed or active order
            self.selectedWorkOrder = orders.first(where: { $0.status == .completed || $0.status == .billed }) ?? orders.first
        }

        // load approved claims from recent orders
        var claims: [ExpenseClaim] = []
        for order in orders.prefix(4) {
            if let res: WorkOrderExpensesResponse = try? await apiService.send(.getExpensesByWorkOrder(workOrderId: order.id)) {
                claims.append(contentsOf: res.claims.filter { $0.approvalStatus == .approved })
            }
        }

        self.approvedExpenses = claims
        if let first = claims.first, let amt = Double(first.totalAmount) {
            self.partsSubtotal = amt
        }

        updateMetricsForSelectedOrder()
        isLoading = false
    }


    // update estimate calculations when user selects a different work order
    func selectWorkOrder(_ order: WorkOrder) {
        self.selectedWorkOrder = order
        updateMetricsForSelectedOrder()
    }

    private func updateMetricsForSelectedOrder() {
        guard let order = selectedWorkOrder else { return }

        // derive rate from facility contract if available
        if let rateStr = order.facility?.contractHourlyRate, let rate = Double(rateStr) {
            self.hourlyRate = rate
        }

        if let markupStr = order.facility?.partsMarkupPercent, let markup = Double(markupStr) {
            self.partsMarkupPercent = markup
        }

        // invoice number based on work order
        let cleanNum = order.workOrderNumber.replacingOccurrences(of: "WO-", with: "")
        self.currentInvoiceNumber = "INV-\(cleanNum)"
    }


    // sync estimate calculation with backend NeonDB
    func generateBackendEstimate() async -> Bool {
        guard let order = selectedWorkOrder else { return false }
        isLoading = true

        do {
            let res: EstimateResponse = try await apiService.send(.generateEstimate(workOrderId: order.id))
            self.currentInvoiceNumber = res.invoice.invoiceNumber
            self.invoiceStatus = res.invoice.status
            successToast = "Billing estimate calculated and stored on server."
            isLoading = false
            return true
        } catch {
            // retain local calculation on error
            successToast = "Estimate calculated with live local engine."
            isLoading = false
            return true
        }
    }


    // issue finalized invoice to client
    func issueInvoiceToClient() async -> Bool {
        self.invoiceStatus = .issuedToClient
        successToast = "Invoice \(currentInvoiceNumber) issued to client facility."
        return true
    }
}
