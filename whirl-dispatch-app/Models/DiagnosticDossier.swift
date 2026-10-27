//
//  DiagnosticDossier.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation
import UIKit

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


// local device captured photo model with geotagging
struct CapturedProofPhoto: Identifiable, Equatable {
    let id: String
    var photoType: PhotoType
    var image: UIImage
    let capturedTimestamp: Date
    let latitude: Double?
    let longitude: Double?
    var notes: String?
    var compressedData: Data?
    var originalByteSize: Int?
    var compressedByteSize: Int?

    var formattedCompressionSavings: String {
        guard let orig = originalByteSize, let comp = compressedByteSize, orig > 0 else {
            return "JPEG 0.7x"
        }
        let compKb = comp / 1024
        let savedPct = max(0, Int((1.0 - Double(comp) / Double(orig)) * 100))
        return "\(compKb) KB (\(savedPct)% saved)"
    }

    static func == (lhs: CapturedProofPhoto, rhs: CapturedProofPhoto) -> Bool {
        lhs.id == rhs.id && lhs.photoType == rhs.photoType && lhs.notes == rhs.notes
    }
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

    init(
        id: String,
        workOrderId: String,
        leadTechnicianId: String,
        equipmentModel: String,
        equipmentSerialNumber: String? = nil,
        baselineSuctionPressurePsi: String? = nil,
        postServiceSuctionPressurePsi: String? = nil,
        baselineDischargePressurePsi: String? = nil,
        postServiceDischargePressurePsi: String? = nil,
        baselineMotorRunningAmps: String? = nil,
        postServiceMotorRunningAmps: String? = nil,
        technicianNotes: String? = nil,
        supervisorReviewNotes: String? = nil,
        isWorkApproved: Bool? = nil,
        checklist: [DossierChecklistItem]? = nil,
        photos: [DossierPhoto]? = nil
    ) {
        self.id = id
        self.workOrderId = workOrderId
        self.leadTechnicianId = leadTechnicianId
        self.equipmentModel = equipmentModel
        self.equipmentSerialNumber = equipmentSerialNumber
        self.baselineSuctionPressurePsi = baselineSuctionPressurePsi
        self.postServiceSuctionPressurePsi = postServiceSuctionPressurePsi
        self.baselineDischargePressurePsi = baselineDischargePressurePsi
        self.postServiceDischargePressurePsi = postServiceDischargePressurePsi
        self.baselineMotorRunningAmps = baselineMotorRunningAmps
        self.postServiceMotorRunningAmps = postServiceMotorRunningAmps
        self.technicianNotes = technicianNotes
        self.supervisorReviewNotes = supervisorReviewNotes
        self.isWorkApproved = isWorkApproved
        self.checklist = checklist
        self.photos = photos
    }

    enum CodingKeys: String, CodingKey {
        case id, workOrderId, leadTechnicianId, equipmentModel, equipmentSerialNumber
        case baselineSuctionPressurePsi, postServiceSuctionPressurePsi
        case baselineDischargePressurePsi, postServiceDischargePressurePsi
        case baselineMotorRunningAmps, postServiceMotorRunningAmps
        case technicianNotes, diagnosticNotes
        case supervisorReviewNotes, isWorkApproved
        case checklist, checklistItems
        case photos, proofPhotos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        workOrderId = try container.decode(String.self, forKey: .workOrderId)
        leadTechnicianId = try container.decode(String.self, forKey: .leadTechnicianId)
        equipmentModel = try container.decode(String.self, forKey: .equipmentModel)
        equipmentSerialNumber = try container.decodeIfPresent(String.self, forKey: .equipmentSerialNumber)
        baselineSuctionPressurePsi = try container.decodeIfPresent(String.self, forKey: .baselineSuctionPressurePsi)
        postServiceSuctionPressurePsi = try container.decodeIfPresent(String.self, forKey: .postServiceSuctionPressurePsi)
        baselineDischargePressurePsi = try container.decodeIfPresent(String.self, forKey: .baselineDischargePressurePsi)
        postServiceDischargePressurePsi = try container.decodeIfPresent(String.self, forKey: .postServiceDischargePressurePsi)
        baselineMotorRunningAmps = try container.decodeIfPresent(String.self, forKey: .baselineMotorRunningAmps)
        postServiceMotorRunningAmps = try container.decodeIfPresent(String.self, forKey: .postServiceMotorRunningAmps)

        technicianNotes = try container.decodeIfPresent(String.self, forKey: .technicianNotes)
            ?? container.decodeIfPresent(String.self, forKey: .diagnosticNotes)
        supervisorReviewNotes = try container.decodeIfPresent(String.self, forKey: .supervisorReviewNotes)
        isWorkApproved = try container.decodeIfPresent(Bool.self, forKey: .isWorkApproved)

        checklist = try container.decodeIfPresent([DossierChecklistItem].self, forKey: .checklist)
            ?? container.decodeIfPresent([DossierChecklistItem].self, forKey: .checklistItems)
        photos = try container.decodeIfPresent([DossierPhoto].self, forKey: .photos)
            ?? container.decodeIfPresent([DossierPhoto].self, forKey: .proofPhotos)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workOrderId, forKey: .workOrderId)
        try container.encode(leadTechnicianId, forKey: .leadTechnicianId)
        try container.encode(equipmentModel, forKey: .equipmentModel)
        try container.encodeIfPresent(equipmentSerialNumber, forKey: .equipmentSerialNumber)
        try container.encodeIfPresent(baselineSuctionPressurePsi, forKey: .baselineSuctionPressurePsi)
        try container.encodeIfPresent(postServiceSuctionPressurePsi, forKey: .postServiceSuctionPressurePsi)
        try container.encodeIfPresent(baselineDischargePressurePsi, forKey: .baselineDischargePressurePsi)
        try container.encodeIfPresent(postServiceDischargePressurePsi, forKey: .postServiceDischargePressurePsi)
        try container.encodeIfPresent(baselineMotorRunningAmps, forKey: .baselineMotorRunningAmps)
        try container.encodeIfPresent(postServiceMotorRunningAmps, forKey: .postServiceMotorRunningAmps)
        try container.encodeIfPresent(technicianNotes, forKey: .technicianNotes)
        try container.encodeIfPresent(supervisorReviewNotes, forKey: .supervisorReviewNotes)
        try container.encodeIfPresent(isWorkApproved, forKey: .isWorkApproved)
        try container.encodeIfPresent(checklist, forKey: .checklist)
        try container.encodeIfPresent(photos, forKey: .photos)
    }
}


struct DossierResponse: Codable {
    let dossier: DiagnosticDossier?
    let checklist: [DossierChecklistItem]?
    let photos: [DossierPhoto]?

    var resolvedChecklist: [DossierChecklistItem] {
        checklist ?? dossier?.checklist ?? []
    }

    var resolvedPhotos: [DossierPhoto] {
        photos ?? dossier?.photos ?? []
    }
}

struct SaveDossierResponse: Codable {
    let message: String?
}
