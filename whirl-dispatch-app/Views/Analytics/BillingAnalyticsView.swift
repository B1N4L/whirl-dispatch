//
//  BillingAnalyticsView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-26.
//

import SwiftUI
import Charts

struct BillingAnalyticsView: View {
    @State private var monthlyMetrics: [MonthlyRevenueMetric] = TelemetrySampleData.monthlyRevenueMetrics
    @State private var laborMetrics: [WeeklyLaborMetric] = TelemetrySampleData.weeklyLaborMetrics
    @State private var pipelineStages: [InvoicePipelineStage] = TelemetrySampleData.pipelineStages

    @State private var totalInvoicedRevenue: Double = 46550.0
    @State private var totalBusinessProfit: Double = 31400.0
    @State private var totalBillableHours: Double = 257.0
    @State private var readyToBillCount: Int = 3

    @State private var selectedMonthMetric: MonthlyRevenueMetric? = nil
    @State private var selectedPipelineStage: InvoicePipelineStage? = nil
    @State private var isLoading: Bool = false

    private let apiService = APIService.shared

    private var monthlyChartItems: [MonthlyChartItem] {
        var items: [MonthlyChartItem] = []
        for m in monthlyMetrics {
            items.append(MonthlyChartItem(month: m.month, seriesName: "Invoiced Revenue", amount: m.invoicedRevenue))
            items.append(MonthlyChartItem(month: m.month, seriesName: "Gross Profit", amount: m.grossProfit))
        }
        return items
    }

    private var targetBenchmark: Double {
        20000.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header overview title
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Payment Clerk Dashboard")
                            .font(.appTitle)
                            .foregroundColor(Color.brandNavy)

                        Spacer()

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button(action: {
                                Task {
                                    await loadDashboardData()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.brandNavy)
                                    .padding(8)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Live billing telemetry, audited field labor utilization, and cash flow pipeline.")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 1. Executive KPI Summary Row
                kpiSummaryRow

                // 2. Chart 1: Revenue vs. Business Profit Margin (Grouped BarMark + RuleMark)
                revenueVsProfitChartCard

                if let selected = selectedMonthMetric {
                    monthDetailCallout(selected)
                }

                // 3. Chart 3: Weekly Technician Labor Utilization & Hours Trend (LineMark + AreaMark + PointMark)
                weeklyLaborUtilizationChartCard

                // 4. Chart 4: Invoice Pipeline & Cash Flow Distribution (Horizontal BarMark)
                invoicePipelineChartCard
            }
            .padding(18)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Financial Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDashboardData()
        }
    }


    // MARK: - Executive KPI Row

    private var kpiSummaryRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            kpiCard(
                title: "Invoiced Revenue",
                value: formatCurrencyCompact(totalInvoicedRevenue),
                subtitle: "Total Billed",
                color: Color.brandNavy,
                icon: "doc.text.fill"
            )

            kpiCard(
                title: "Business Profit",
                value: formatCurrencyCompact(totalBusinessProfit),
                subtitle: "Labor + Markup",
                color: Color.statusGreen,
                icon: "banknote.fill"
            )

            kpiCard(
                title: "Billable Labor",
                value: "\(Int(totalBillableHours)) hrs",
                subtitle: "Audited Shifts",
                color: Color.brandNavy,
                icon: "clock.badge.checkmark.fill"
            )

            kpiCard(
                title: "Ready to Bill",
                value: "\(readyToBillCount) Jobs",
                subtitle: "Pending Invoicing",
                color: Color.statusAmber,
                icon: "tray.full.fill"
            )
        }
    }

    private func kpiCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
    }


    // MARK: - Chart 1: Revenue vs. Business Profit Margin

    private var revenueVsProfitChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Revenue vs. Business Profit Margin", systemImage: "chart.bar.xaxis")
                        .font(.appHeadline)
                        .foregroundColor(Color.brandNavy)

                    Text("Monthly comparison of total invoiced revenue against retained business profit (Option B labor + markup).")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Grouped BarMark")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentBlue.opacity(0.12))
                    .foregroundColor(Color.accentBlue)
                    .cornerRadius(4)
            }

            Divider()

            Chart {
                ForEach(monthlyChartItems) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount (LKR)", item.amount)
                    )
                    .position(by: .value("Series", item.seriesName))
                    .foregroundStyle(item.seriesName == "Invoiced Revenue" ? Color.brandNavy : Color.statusGreen)
                    .cornerRadius(5)
                }

                RuleMark(
                    y: .value("Benchmark", targetBenchmark)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundStyle(Color.statusAmber)
                .annotation(position: .top, alignment: .leading) {
                    Text("Target LKR 20k")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.statusAmber)
                        .padding(.leading, 4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("LKR \(Int(v / 1000))k")
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let m = value.as(String.self) {
                            Text(m)
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
            }
            .frame(height: 220)
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Revenue vs Business Profit Grouped Bar Chart")
            .accessibilityHint("Compares monthly invoiced revenue with net profit against the LKR 20,000 baseline target.")

            // Legend and month selector row
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.brandNavy)
                        .frame(width: 10, height: 10)
                    Text("Invoiced Revenue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.statusGreen)
                        .frame(width: 10, height: 10)
                    Text("Gross Profit (Labor + Markup)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    ForEach(monthlyMetrics) { m in
                        Button(action: {
                            if selectedMonthMetric?.month == m.month {
                                selectedMonthMetric = nil
                            } else {
                                selectedMonthMetric = m
                            }
                        }) {
                            Text(m.month)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    selectedMonthMetric?.month == m.month
                                        ? Color.brandNavy
                                        : Color(uiColor: .tertiarySystemGroupedBackground)
                                )
                                .foregroundColor(
                                    selectedMonthMetric?.month == m.month
                                        ? .white
                                        : .secondary
                                )
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func monthDetailCallout(_ metric: MonthlyRevenueMetric) -> some View {
        let marginPct = metric.invoicedRevenue > 0
            ? Int((metric.grossProfit / metric.invoicedRevenue) * 100)
            : 0

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(metric.month) Performance Detail")
                    .font(.appSubheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandNavy)

                Text("Target Status: \(metric.invoicedRevenue >= metric.targetRevenue ? "Target Achieved" : "Under Target")")
                    .font(.caption2)
                    .foregroundColor(metric.invoicedRevenue >= metric.targetRevenue ? Color.statusGreen : Color.statusAmber)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Invoiced: LKR \(Int(metric.invoicedRevenue).formatted())")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)

                Text("Profit: LKR \(Int(metric.grossProfit).formatted()) (\(marginPct)% margin)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.statusGreen)
            }

            Button(action: { selectedMonthMetric = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.statusGreen.opacity(0.10))
        .cornerRadius(8)
    }


    // MARK: - Chart 3: Weekly Technician Labor Utilization & Hours Trend

    private var weeklyLaborUtilizationChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Weekly Technician Labor Hours Trend", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.appHeadline)
                        .foregroundColor(Color.brandNavy)

                    Text("Audited shift duration across the field crew benchmarked against 40-hour weekly shift capacity.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("LineMark & AreaMark")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.statusGreen.opacity(0.12))
                    .foregroundColor(Color.statusGreen)
                    .cornerRadius(4)
            }

            Divider()

            Chart {
                ForEach(laborMetrics) { metric in
                    AreaMark(
                        x: .value("Day", metric.day),
                        y: .value("Hours", metric.billableHours)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.statusGreen.opacity(0.30), Color.statusGreen.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", metric.day),
                        y: .value("Hours", metric.billableHours)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.statusGreen)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Day", metric.day),
                        y: .value("Hours", metric.billableHours)
                    )
                    .foregroundStyle(Color.brandNavy)
                    .annotation(position: .top) {
                        Text("\(Int(metric.billableHours))h")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                RuleMark(
                    y: .value("Target Shift", 40.0)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                .foregroundStyle(Color.statusAmber)
                .annotation(position: .leading, alignment: .bottom) {
                    Text("40h Capacity")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.statusAmber)
                        .padding(.leading, 4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))h")
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Weekly Technician Labor Hours Trend Curve")
            .accessibilityHint("Displays daily on-site technician hours with a Catmull-Rom curve against a 40-hour shift target.")

            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.statusGreen)
                        .frame(width: 8, height: 8)
                    Text("Audited On-Site Hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.statusAmber)
                        .frame(width: 12, height: 2)
                    Text("Standard Capacity (40h)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


    // MARK: - Chart 4: Invoice Pipeline & Cash Flow Distribution

    private var invoicePipelineChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Invoice Pipeline & Cash Flow Distribution", systemImage: "tray.full.fill")
                        .font(.appHeadline)
                        .foregroundColor(Color.brandNavy)

                    Text("Active dispatches and commercial invoices segmented by lifecycle stage.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Horizontal BarMark")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.statusAmber.opacity(0.15))
                    .foregroundColor(Color.statusAmber)
                    .cornerRadius(4)
            }

            Divider()

            Chart {
                ForEach(pipelineStages) { stage in
                    BarMark(
                        x: .value("Amount (LKR)", stage.totalAmount),
                        y: .value("Stage", stage.stage)
                    )
                    .foregroundStyle(stageColor(for: stage.stage))
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(stage.formattedAmount) (\(stage.count) jobs)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.leading, 6)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("LKR \(Int(v / 1000))k")
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(s)
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
            }
            .frame(height: 140)
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Invoice Pipeline Horizontal Bar Chart")
            .accessibilityHint("Visualizes amount and jobs locked in Ready to Bill, Issued, and Paid stages.")

            Divider()

            // Stage cards row
            HStack(spacing: 12) {
                ForEach(pipelineStages) { stage in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(stageColor(for: stage.stage))
                                .frame(width: 8, height: 8)
                            Text(stage.stage)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }

                        Text(stage.formattedAmount)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(stageColor(for: stage.stage))

                        Text("\(stage.count) Dispatches")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func stageColor(for stage: String) -> Color {
        switch stage {
        case "Ready to Bill": return Color.statusAmber
        case "Issued to Client": return Color.brandNavy
        case "Settled & Paid": return Color.statusGreen
        default: return Color.gray
        }
    }


    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true
        do {
            let res: DashboardAnalyticsResponse = try await apiService.send(.getDashboardAnalytics)
            self.totalInvoicedRevenue = res.summary.totalInvoicedRevenue
            self.totalBusinessProfit = res.summary.totalBusinessProfit
            self.totalBillableHours = res.summary.totalBillableHours
            self.readyToBillCount = res.summary.readyToBillCount

            if !res.monthlyRevenue.isEmpty {
                self.monthlyMetrics = res.monthlyRevenue
            }
            if !res.weeklyLaborHours.isEmpty {
                self.laborMetrics = res.weeklyLaborHours
            }
            if !res.pipelineStages.isEmpty {
                self.pipelineStages = res.pipelineStages
            }
        } catch {
            // fallback: retain TelemetrySampleData defaults
        }
        isLoading = false
    }

    private func formatCurrencyCompact(_ value: Double) -> String {
        AppCurrency.formatCompact(value)
    }
}
