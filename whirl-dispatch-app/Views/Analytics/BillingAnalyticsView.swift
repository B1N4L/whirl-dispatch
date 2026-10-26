//
//  BillingAnalyticsView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-26.
//

import SwiftUI
import Charts

struct BillingAnalyticsView: View {
    enum TelemetryTab: String, CaseIterable, Identifiable {
        case all = "Executive View"
        case revenue = "Revenue (Bar)"
        case parts = "Parts (Donut)"
        case labor = "Labor (Trend)"

        var id: String { rawValue }
    }

    @State private var selectedTab: TelemetryTab = .all
    @State private var metrics: [FacilityRevenueMetric] = TelemetrySampleData.facilityRevenueMetrics
    @State private var partsMetrics: [PartsExpenseCategoryMetric] = TelemetrySampleData.partsCategoryMetrics
    @State private var laborMetrics: [LaborHoursTrendMetric] = TelemetrySampleData.laborHoursMetrics
    @State private var selectedMetric: FacilityRevenueMetric? = nil


    private var totalRevenue: Double {
        metrics.reduce(0) { $0 + $1.revenue }
    }

    private var averageRevenue: Double {
        guard !metrics.isEmpty else { return 0 }
        return totalRevenue / Double(metrics.count)
    }

    private var totalCompletedDispatches: Int {
        metrics.reduce(0) { $0 + $1.completedWorkOrders }
    }

    private var totalPartsSpend: Double {
        partsMetrics.reduce(0) { $0 + $1.amount }
    }

    private var totalLaborHours: Double {
        laborMetrics.reduce(0) { $0 + $1.billableHours }
    }


    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // telemetry segment filter
                Picker("Telemetry Stream", selection: $selectedTab) {
                    ForEach(TelemetryTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 2)

                // executive kpi cards
                kpiSummaryRow

                // 1. facility revenue bar mark chart
                if selectedTab == .all || selectedTab == .revenue {
                    facilityRevenueBarChartCard

                    if let selected = selectedMetric {
                        facilityDetailCalloutCard(selected)
                    }
                }

                // 2. parts expense allocation donut chart (SectorMark)
                if selectedTab == .all || selectedTab == .parts {
                    partsExpenseDonutChartCard
                }

                // 3. labor hours utilization trend line chart (LineMark & AreaMark)
                if selectedTab == .all || selectedTab == .labor {
                    laborHoursTrendChartCard
                }

                // 4. tabular breakdown card
                if selectedTab == .all || selectedTab == .revenue {
                    facilityBreakdownTableCard
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Financial & Dispatch Telemetry")
        .navigationBarTitleDisplayMode(.inline)
    }


    // MARK: - KPI Executive Summary Cards

    private var kpiSummaryRow: some View {
        HStack(spacing: 12) {
            kpiCard(
                title: "Total Revenue",
                value: "$\(Int(totalRevenue).formatted())",
                subtitle: "6 Commercial Sites",
                color: Color.brandNavy
            )

            kpiCard(
                title: "Parts Spend",
                value: "$\(Int(totalPartsSpend).formatted())",
                subtitle: "5 HVAC Categories",
                color: Color.statusAmber
            )

            kpiCard(
                title: "Labor Hours",
                value: "\(Int(totalLaborHours))h",
                subtitle: "7-Day Utilization",
                color: Color.statusGreen
            )
        }
    }

    private func kpiCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .monospaced))
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


    // MARK: - 1. Facility Revenue Bar Chart (BarMark)

    private var facilityRevenueBarChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Commercial Facility Revenue Telemetry", systemImage: "chart.bar.fill")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Spacer()

                Text("BarMark")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentBlue.opacity(0.12))
                    .foregroundColor(Color.accentBlue)
                    .cornerRadius(4)
            }

            Divider()

            Chart {
                ForEach(metrics) { item in
                    BarMark(
                        x: .value("Facility", item.facilityCode),
                        y: .value("Revenue ($)", item.revenue)
                    )
                    .foregroundStyle(
                        selectedMetric?.id == item.id
                            ? Color.statusGreen
                            : (item.isTargetAchieved ? Color.brandNavy : Color.statusAmber)
                    )
                    .cornerRadius(6)
                    .annotation(position: .top, alignment: .center) {
                        Text("$\(Int(item.revenue / 1000))k")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                // average revenue reference rule mark
                RuleMark(
                    y: .value("Average", averageRevenue)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundStyle(Color.statusAmber)
                .annotation(position: .leading, alignment: .bottom) {
                    Text("Avg $\(Int(averageRevenue))")
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
                            Text("$\(Int(v / 1000))k")
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let code = value.as(String.self) {
                            Text(code)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Commercial Facility Revenue Telemetry Bar Chart")
            .accessibilityHint("Displays revenue across commercial facilities. Average benchmark is $\(Int(averageRevenue)).")

            // legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brandNavy)
                        .frame(width: 8, height: 8)
                    Text("Target Met")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.statusAmber)
                        .frame(width: 8, height: 8)
                    Text("Under Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Tap bar to inspect")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


    // MARK: - 2. Parts Category Donut Chart (SectorMark)

    private var partsExpenseDonutChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Parts Expense Allocation", systemImage: "chart.pie.fill")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Spacer()

                Text("SectorMark Donut")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.statusAmber.opacity(0.15))
                    .foregroundColor(Color.statusAmber)
                    .cornerRadius(4)
            }

            Divider()

            ZStack {
                Chart(partsMetrics) { part in
                    SectorMark(
                        angle: .value("Amount", part.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", part.categoryName))
                }
                .chartLegend(.hidden)
                .frame(height: 190)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Parts Expense Allocation Donut Chart")
                .accessibilityHint("Total parts spend $\(Int(totalPartsSpend)).")

                // centered donut metric summary
                VStack(spacing: 2) {
                    Text("$\(Int(totalPartsSpend).formatted())")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandNavy)
                    Text("Wholesale Parts")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // parts category breakdown items
            VStack(spacing: 8) {
                ForEach(partsMetrics) { item in
                    let pct = Int((item.amount / totalPartsSpend) * 100)
                    HStack {
                        Circle()
                            .fill(categoryColor(for: item.categoryName))
                            .frame(width: 8, height: 8)

                        Text(item.categoryName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(pct)%")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text("$\(Int(item.amount).formatted())")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.brandNavy)
                            .frame(width: 70, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func categoryColor(for name: String) -> Color {
        switch name {
        case "Compressor Motors": return Color.brandNavy
        case "Refrigerant & Valves": return Color.accentBlue
        case "Electrical Controls": return Color.statusAmber
        case "Condenser Airflow": return Color.statusGreen
        default: return Color.gray
        }
    }


    // MARK: - 3. Labor Hours Trend Line Chart (LineMark & AreaMark)

    private var laborHoursTrendChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Technician Labor Hours Trend", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

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
                    // gradient area fill under curve
                    AreaMark(
                        x: .value("Day", metric.dayLabel),
                        y: .value("Hours", metric.billableHours)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.statusGreen.opacity(0.28), Color.statusGreen.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // trend curve line
                    LineMark(
                        x: .value("Day", metric.dayLabel),
                        y: .value("Hours", metric.billableHours)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.statusGreen)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    // point marks on each day
                    PointMark(
                        x: .value("Day", metric.dayLabel),
                        y: .value("Hours", metric.billableHours)
                    )
                    .foregroundStyle(Color.brandNavy)
                    .annotation(position: .top) {
                        Text("\(Int(metric.billableHours))h")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                // 40 hours target weekly pace threshold rule
                RuleMark(
                    y: .value("Target Shift", 40.0)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                .foregroundStyle(Color.statusAmber)
                .annotation(position: .leading, alignment: .bottom) {
                    Text("40h Target")
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
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                }
            }
            .frame(height: 190)
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Technician Labor Hours Trend Line Chart")
            .accessibilityHint("Shows weekly billable labor hours trend against the 40-hour target.")

            HStack {
                Circle()
                    .fill(Color.statusGreen)
                    .frame(width: 8, height: 8)
                Text("Billable Hours Logged")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.statusAmber)
                        .frame(width: 12, height: 2)
                    Text("Baseline Capacity (40h)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


    // MARK: - Facility Detail Callout

    private func facilityDetailCalloutCard(_ item: FacilityRevenueMetric) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.facilityName)
                        .font(.appHeadline)
                        .fontWeight(.bold)
                    Text(item.billingCategory)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    selectedMetric = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Invoiced")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(Int(item.revenue).formatted())")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandNavy)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(Int(item.targetRevenue).formatted())")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Dispatches")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(item.completedWorkOrders) Jobs")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.statusGreen)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.statusGreen.opacity(0.4), lineWidth: 1.5)
        )
    }


    // MARK: - Facility Breakdown Table

    private var facilityBreakdownTableCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Facility Breakdown Ledger", systemImage: "list.clipboard")
                .font(.appSubheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.brandNavy)

            Divider()

            ForEach(metrics) { item in
                Button(action: {
                    selectedMetric = (selectedMetric?.id == item.id ? nil : item)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.facilityName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("\(item.facilityCode) • \(item.completedWorkOrders) dispatches")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(Int(item.revenue).formatted())")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(item.isTargetAchieved ? Color.statusGreen : Color.statusAmber)

                            Text(item.isTargetAchieved ? "+$\(Int(item.revenue - item.targetRevenue))" : "-$\(Int(item.targetRevenue - item.revenue))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if item.id != metrics.last?.id {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
