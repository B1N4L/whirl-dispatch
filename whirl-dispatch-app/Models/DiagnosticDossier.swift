//
//  DiagnosticDossier.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation

enum PhotoType: String, Codable, CaseIterable {
    case baselineBefore = "BASELINE_BEFORE"
    case postServiceAfter = "POST_SERVICE_AFTER"
    case defectEvidence = "DEFECT_EVIDENCE"
    case replacedPart = "REPLACED_PART"

   var label: String {
       switch self {
       case .baselineBefore: return "Before Service"
       case .postServiceAfter: return "After Service"
       case .defectEvidence: return "Defect Proof"
       case .replacedPart: return "Replaced Component"
       }
   }
}


enum ChecklistCategory: String, Codable, CaseIterable, Identifiable {
    case compressor = "COMPRESSOR_SYSTEM"
    case refrigerant = "REFRIGERANT_CIRCUIT"
    case electrical = "ELECTRICAL_CONTROLS"
    case airflow = "CONDENSER_AIR_FLOW"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compressor: return "Compressor System"
        case .refrigerant: return "Refrigerant Circuit"
        case .electrical: return "Electrical & Controls"
        case .airflow: return "Condenser & Airflow"
        }
    }

    var iconName: String {
        switch self {
        case .compressor: return "gearshape.2.fill"
        case .refrigerant: return "wind"
        case .electrical: return "bolt.fill"
        case .airflow: return "air.purifier.fill"
        }
    }
}


struct DossierChecklistItem: Identifiable, Codable, Equatable {
    let id: String
    let category: ChecklistCategory
    var itemLabel: String
    var isChecked: Bool
    var notes: String?
}


struct DossierPhoto: Identifiable, Codable, Equatable {
    let id: String
    let diagnosticDossierId: String
    let photoType: PhotoType
    let photoUrl: String
    let capturedTimestamp: String?
    let latitude: Double?
    let longitude: Double?
}


struct DiagnosticDossier: Identifiable, Codable, Equatable {
    let id: String
    let workOrderId: String
    let leadTechnicianId: String
    var equipmentModel: String
    var equipmentSerialNumber: String?
    var baselineSuctionPressurePsi: String?
    var postServiceSuctionPressurePsi: String?
    var baselineDischargePressurePsi: String?
    var postServiceDischargePressurePsi: String?
    var baselineMotorRunningAmps: String?
    var postServiceMotorRunningAmps: String?
    var technicianNotes: String?
    var supervisorReviewNotes: String?
    var isWorkApproved: Bool?
    var checklist: [DossierChecklistItem]?
    var photos: [DossierPhoto]?
}


struct DossierResponse: Codable {
    let dossier: DiagnosticDossier?
    let checklist: [DossierChecklistItem]?
    let photos: [DossierPhoto]?
}

struct SaveDossierResponse: Codable {
    let message: String?
}
