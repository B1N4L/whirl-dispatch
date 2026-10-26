//
//  TelemetryModels.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-26.
//

import Foundation

struct FacilityRevenueMetric: Identifiable, Equatable, Hashable {
    let id: String
    let facilityName: String
    let facilityCode: String
    let revenue: Double
    let targetRevenue: Double
    let completedWorkOrders: Int
    let billingCategory: String

    var isTargetAchieved: Bool {
        revenue >= targetRevenue
    }
}


struct PartsExpenseCategoryMetric: Identifiable, Equatable {
    let id: String
    let categoryName: String
    let amount: Double
    let itemsCount: Int
    let colorHex: String
}


struct LaborHoursTrendMetric: Identifiable, Equatable {
    let id: String
    let dayLabel: String
    let date: Date
    let billableHours: Double
    let targetHours: Double
}


enum TelemetrySampleData {
    static let facilityRevenueMetrics: [FacilityRevenueMetric] = [
        FacilityRevenueMetric(
            id: "rev-01",
            facilityName: "Cargills Central",
            facilityCode: "CAR-01",
            revenue: 4850.0,
            targetRevenue: 4000.0,
            completedWorkOrders: 6,
            billingCategory: "Retail Supermarket"
        ),
        FacilityRevenueMetric(
            id: "rev-02",
            facilityName: "Dialog Axiata Hub",
            facilityCode: "DIA-02",
            revenue: 7200.0,
            targetRevenue: 6500.0,
            completedWorkOrders: 8,
            billingCategory: "Telecommunications"
        ),
        FacilityRevenueMetric(
            id: "rev-03",
            facilityName: "Apex Chiller Plant",
            facilityCode: "APX-03",
            revenue: 9400.0,
            targetRevenue: 8000.0,
            completedWorkOrders: 11,
            billingCategory: "Industrial Cold Room"
        ),
        FacilityRevenueMetric(
            id: "rev-04",
            facilityName: "Keells Mega Warehouse",
            facilityCode: "KEE-04",
            revenue: 3600.0,
            targetRevenue: 4500.0,
            completedWorkOrders: 4,
            billingCategory: "Logistics Warehouse"
        ),
        FacilityRevenueMetric(
            id: "rev-05",
            facilityName: "Hilton Rooftop Chiller",
            facilityCode: "HLT-05",
            revenue: 6100.0,
            targetRevenue: 5500.0,
            completedWorkOrders: 7,
            billingCategory: "Hospitality HVAC"
        ),
        FacilityRevenueMetric(
            id: "rev-06",
            facilityName: "Hemas Cleanroom Plant",
            facilityCode: "HEM-06",
            revenue: 5350.0,
            targetRevenue: 5000.0,
            completedWorkOrders: 5,
            billingCategory: "Healthcare Cleanroom"
        )
    ]

    static let partsCategoryMetrics: [PartsExpenseCategoryMetric] = [
        PartsExpenseCategoryMetric(id: "part-01", categoryName: "Compressor Motors", amount: 14250.0, itemsCount: 6, colorHex: "#0F2B48"),
        PartsExpenseCategoryMetric(id: "part-02", categoryName: "Refrigerant & Valves", amount: 8400.0, itemsCount: 18, colorHex: "#1E88E5"),
        PartsExpenseCategoryMetric(id: "part-03", categoryName: "Electrical Controls", amount: 6200.0, itemsCount: 14, colorHex: "#E65100"),
        PartsExpenseCategoryMetric(id: "part-04", categoryName: "Condenser Airflow", amount: 4800.0, itemsCount: 9, colorHex: "#2E7D32"),
        PartsExpenseCategoryMetric(id: "part-05", categoryName: "Driers & Gaskets", amount: 2850.0, itemsCount: 22, colorHex: "#78909C")
    ]

    static let laborHoursMetrics: [LaborHoursTrendMetric] = [
        LaborHoursTrendMetric(id: "day-01", dayLabel: "Mon", date: Date().addingTimeInterval(-6 * 86400), billableHours: 38.5, targetHours: 40.0),
        LaborHoursTrendMetric(id: "day-02", dayLabel: "Tue", date: Date().addingTimeInterval(-5 * 86400), billableHours: 44.0, targetHours: 40.0),
        LaborHoursTrendMetric(id: "day-03", dayLabel: "Wed", date: Date().addingTimeInterval(-4 * 86400), billableHours: 41.5, targetHours: 40.0),
        LaborHoursTrendMetric(id: "day-04", dayLabel: "Thu", date: Date().addingTimeInterval(-3 * 86400), billableHours: 46.5, targetHours: 40.0),
        LaborHoursTrendMetric(id: "day-05", dayLabel: "Fri", date: Date().addingTimeInterval(-2 * 86400), billableHours: 42.0, targetHours: 40.0),
        LaborHoursTrendMetric(id: "day-06", dayLabel: "Sat", date: Date().addingTimeInterval(-1 * 86400), billableHours: 28.5, targetHours: 25.0),
        LaborHoursTrendMetric(id: "day-07", dayLabel: "Sun", date: Date(), billableHours: 16.0, targetHours: 15.0)
    ]
}
