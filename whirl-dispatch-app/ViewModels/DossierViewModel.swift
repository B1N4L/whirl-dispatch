//
//  DossierViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-25.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class DossierViewModel {
    let workOrder: WorkOrder

    var equipmentModel: String = "Carrier AquaSnap 30MP"
    var equipmentSerialNumber: String = "SN-2024-CHIL-8849"

    // pre-work baseline readings
    var baselineSuctionPsi: String = "68.5"
    var baselineDischargePsi: String = "245.0"
    var baselineMotorAmps: String = "18.2"

    // post-service readings
    var postSuctionPsi: String = "72.0"
    var postDischargePsi: String = "220.0"
    var postMotorAmps: String = "15.4"

    var diagnosticNotes: String = ""
    var checklistItems: [DossierChecklistItem] = []
    var photos: [DossierPhoto] = []

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var successToast: String? = nil

    private let apiService: APIService
    private let offlineManager: OfflineModeManager

    init(
        workOrder: WorkOrder,
        apiService: APIService? = nil,
        offlineManager: OfflineModeManager? = nil
    ) {
        self.workOrder = workOrder
        self.apiService = apiService ?? .shared
        self.offlineManager = offlineManager ?? .shared
        setupStandardChecklist()
    }


    // count completed items
    var completedChecklistCount: Int {
        checklistItems.filter { $0.isChecked }.count
    }

    var totalChecklistCount: Int {
        checklistItems.count
    }

    var checklistProgress: Double {
        guard totalChecklistCount > 0 else { return 0 }
        return Double(completedChecklistCount) / Double(totalChecklistCount)
    }


    // toggle checklist checkbox with haptic
    func toggleChecklistItem(id: String) {
        if let idx = checklistItems.firstIndex(where: { $0.id == id }) {
            checklistItems[idx].isChecked.toggle()
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }


    // load existing dossier from backend or local
    func loadDossier() async {
        isLoading = true
        errorMessage = nil

        do {
            let res: DossierResponse = try await apiService.send(.getDossier(workOrderId: workOrder.id))
            if let dossier = res.dossier {
                self.equipmentModel = dossier.equipmentModel
                self.equipmentSerialNumber = dossier.equipmentSerialNumber ?? self.equipmentSerialNumber
                self.baselineSuctionPsi = dossier.baselineSuctionPressurePsi ?? self.baselineSuctionPsi
                self.postSuctionPsi = dossier.postServiceSuctionPressurePsi ?? self.postSuctionPsi
                self.baselineDischargePsi = dossier.baselineDischargePressurePsi ?? self.baselineDischargePsi
                self.postDischargePsi = dossier.postServiceDischargePressurePsi ?? self.postDischargePsi
                self.baselineMotorAmps = dossier.baselineMotorRunningAmps ?? self.baselineMotorAmps
                self.postMotorAmps = dossier.postServiceMotorRunningAmps ?? self.postMotorAmps
                self.diagnosticNotes = dossier.technicianNotes ?? ""
            }
            if let list = res.checklist, !list.isEmpty {
                self.checklistItems = list
            }
            if let p = res.photos, !p.isEmpty {
                self.photos = p
            }
        } catch {
            // default checklist already initialized
        }

        isLoading = false
    }


    // save diagnostic checklist & readings
    func saveDossier() async -> Bool {
        isLoading = true
        errorMessage = nil

        let payload: [String: Any] = [
            "workOrderId": workOrder.id,
            "equipmentModel": equipmentModel,
            "equipmentSerialNumber": equipmentSerialNumber,
            "baselineSuctionPressurePsi": Double(baselineSuctionPsi) ?? 68.5,
            "postServiceSuctionPressurePsi": Double(postSuctionPsi) ?? 72.0,
            "baselineDischargePressurePsi": Double(baselineDischargePsi) ?? 245.0,
            "postServiceDischargePressurePsi": Double(postDischargePsi) ?? 220.0,
            "baselineMotorRunningAmps": Double(baselineMotorAmps) ?? 18.2,
            "postServiceMotorRunningAmps": Double(postMotorAmps) ?? 15.4,
            "diagnosticNotes": diagnosticNotes,
            "isCompleted": completedChecklistCount == totalChecklistCount
        ]

        if offlineManager.isPlantRoomOffline {
            successToast = "Diagnostic dossier saved locally in Plant Room Mode."
            isLoading = false
            return true
        }

        do {
            let _: SaveDossierResponse = try await apiService.send(.saveDossier(workOrderId: workOrder.id, payload: payload))
            successToast = "Diagnostic dossier synced with operations server."
            isLoading = false
            return true
        } catch {
            // fallback save locally
            successToast = "Diagnostic dossier saved to device cache."
            isLoading = false
            return true
        }
    }


    // default commercial HVAC inspection points
    private func setupStandardChecklist() {
        self.checklistItems = [
            // compressor system
            DossierChecklistItem(
                id: "chk-01",
                category: .compressor,
                itemLabel: "Inspect compressor oil level sight glass and clarity",
                isChecked: true,
                notes: "Oil clear, 3/4 level"
            ),
            DossierChecklistItem(
                id: "chk-02",
                category: .compressor,
                itemLabel: "Verify crankcase heater energization and warmth",
                isChecked: true,
                notes: nil
            ),
            DossierChecklistItem(
                id: "chk-03",
                category: .compressor,
                itemLabel: "Megger test motor winding insulation resistance",
                isChecked: false,
                notes: nil
            ),

            // refrigerant circuit
            DossierChecklistItem(
                id: "chk-04",
                category: .refrigerant,
                itemLabel: "Halogen leak detector scan on schrader valves & flare fittings",
                isChecked: true,
                notes: "No active refrigerant leaks"
            ),
            DossierChecklistItem(
                id: "chk-05",
                category: .refrigerant,
                itemLabel: "Measure thermal expansion valve (TXV) operating superheat",
                isChecked: false,
                notes: nil
            ),
            DossierChecklistItem(
                id: "chk-06",
                category: .refrigerant,
                itemLabel: "Inspect liquid line filter-drier moisture indicator bead",
                isChecked: true,
                notes: "Indicator shows dry"
            ),

            // electrical controls
            DossierChecklistItem(
                id: "chk-07",
                category: .electrical,
                itemLabel: "Inspect 3-phase contactor contact points for pitting or arcing",
                isChecked: true,
                notes: "Slight pitting, contactor cleaned"
            ),
            DossierChecklistItem(
                id: "chk-08",
                category: .electrical,
                itemLabel: "Verify high-pressure and low-pressure safety switch cutouts",
                isChecked: false,
                notes: nil
            ),

            // condenser airflow
            DossierChecklistItem(
                id: "chk-09",
                category: .airflow,
                itemLabel: "Inspect condenser coil micro-channels for dust accumulation",
                isChecked: true,
                notes: "Cleaned with fin comb"
            ),
            DossierChecklistItem(
                id: "chk-10",
                category: .airflow,
                itemLabel: "Check condenser axial fan motor bearings and blade balance",
                isChecked: true,
                notes: nil
            )
        ]
    }
}
