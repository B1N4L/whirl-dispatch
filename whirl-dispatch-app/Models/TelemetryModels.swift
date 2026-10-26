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
}
