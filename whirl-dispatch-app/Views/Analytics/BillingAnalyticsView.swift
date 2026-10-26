//
//  BillingAnalyticsView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-26.
//

import SwiftUI
import Charts

struct BillingAnalyticsView: View {
    @State private var metrics: [FacilityRevenueMetric] = TelemetrySampleData.facilityRevenueMetrics
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


    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // kpi executive summary cards
                kpiSummaryRow

                // primary bar mark chart card
                facilityRevenueBarChartCard

                // selected facility detail callout
                if let selected = selectedMetric {
                    facilityDetailCalloutCard(selected)
                }

                // tabular breakdown card
                facilityBreakdownTableCard
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Revenue & Dispatch Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }


    // MARK: - Subviews

    private var kpiSummaryRow: some View {
        HStack(spacing: 12) {
            kpiCard(
                title: "Total Revenue",
                value: "$\(Int(totalRevenue).formatted())",
                subtitle: "6 Commercial Sites",
                color: Color.brandNavy
            )

            kpiCard(
                title: "Dispatches Done",
                value: "\(totalCompletedDispatches)",
                subtitle: "Completed Jobs",
                color: Color.accentBlue
            )

            kpiCard(
                title: "Site Average",
                value: "$\(Int(averageRevenue).formatted())",
                subtitle: "Mean per Facility",
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


    private var facilityRevenueBarChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Commercial Facility Revenue Telemetry", systemImage: "chart.bar.fill")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Spacer()

                Text("Billing Cycle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
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
            .frame(height: 220)
            .padding(.top, 8)

            // chart legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brandNavy)
                        .frame(width: 8, height: 8)
                    Text("Target Exceeded")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.statusAmber)
                        .frame(width: 8, height: 8)
                    Text("Below Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Tap bar to inspect")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


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
