//
//  NewExpenseSheet.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-22.
//

import SwiftUI

struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    var workOrders: [WorkOrder]
    var preselectedWorkOrderId: String?
    var onSubmit: (String, String, String?, Double, Int, String) async -> Bool

    @State private var selectedWorkOrderId: String = ""
    @State private var vendorName: String = ""
    @State private var invoiceNumber: String = ""
    @State private var partDescription: String = ""
    @State private var quantity: Int = 1
    @State private var unitPriceString: String = ""

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil


    var body: some View {
        NavigationStack {
          Form {
              // section 1: dispatches
              Section(header: Text("Assigned Work Order")) {
                  if workOrders.isEmpty {
                      Text("No active work orders available")
                          .font(.appSubheadline)
                          .foregroundColor(.secondary)
                  } else {
                      Picker("Work Order", selection: $selectedWorkOrderId) {
                          ForEach(workOrders) { wo in
                              Text("\(wo.workOrderNumber) - \(wo.title)")
                                  .tag(wo.id)
                          }
                      }
                  }
              }

              // section 2: vendor and receipt
              Section(header: Text("Supply House & Receipt")) {
                  TextField("Store / Vendor Name", text: $vendorName)
                      .textInputAutocapitalization(.words)

                  TextField("Invoice / Receipt # (optional)", text: $invoiceNumber)
                      .textInputAutocapitalization(.characters)
              }


              // section 3: parts detail
              Section(header: Text("Emergency Part Details")) {
                  TextField("Part Description (e.g. Capacitor 45/5)", text: $partDescription)

                  Stepper(value: $quantity, in: 1...99) {
                     HStack {
                         Text("Quantity")
                         Spacer()
                         Text("\(quantity)")
                             .fontWeight(.semibold)
                     }
                  }

                  HStack {
                      Text("Unit Price ($)")
                      Spacer()
                      TextField("0.00", text: $unitPriceString)
                          .keyboardType(.decimalPad)
                          .multilineTextAlignment(.trailing)
                          .frame(width: 120)
                  }
              }


              // section 4: camera placeholder
              Section(header: Text("Proof of Purchase")) {
                  Button(action: {
                      // optical camera capture will be wired in Phase 11
                  }) {
                      HStack(spacing: 12) {
                          Image(systemName: "camera.viewfinder")
                              .font(.system(size: 26))
                              .foregroundColor(Color.brandNavy)

                          VStack(alignment: .leading, spacing: 2) {
                              Text("Capture Receipt Photo")
                                  .font(.appSubheadline)
                                  .foregroundColor(Color.brandNavy)
                              Text("Attached standard purchase ticket")
                                  .font(.appCaption)
                                  .foregroundColor(.secondary)
                          }
                          Spacer()
                          Image(systemName: "checkmark.circle.fill")
                              .foregroundColor(Color.statusGreen)
                      }
                      .padding(.vertical, 4)
                  }
              }


              // error banner if validation fails
              if let err = errorMessage {
                  Section {
                      Text(err)
                          .font(.appFootnote)
                          .foregroundColor(Color.statusRed)
                  }
              }
          }
          .navigationTitle("Log Field Expense")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                  Button("Cancel") {
                      dismiss()
                  }
                  .disabled(isSubmitting)
              }

              ToolbarItem(placement: .confirmationAction) {
                  Button(action: {
                      submitForm()
                  }) {
                      if isSubmitting {
                          ProgressView()
                              .scaleEffect(0.8)
                      } else {
                          Text("Submit")
                              .fontWeight(.bold)
                      }
                  }
                  .disabled(isSubmitting || vendorName.trimmingCharacters(in: .whitespaces).isEmpty || partDescription.trimmingCharacters(in: .whitespaces).isEmpty)
              }
          }
          .onAppear {
              if let pre = preselectedWorkOrderId, !pre.isEmpty {
                  selectedWorkOrderId = pre
              } else if let first = workOrders.first {
                  selectedWorkOrderId = first.id
              }
          }
        }
    }


    private func submitForm() {
        guard !selectedWorkOrderId.isEmpty else {
            errorMessage = "Please select an assigned work order."
            return
        }

        let cleanVendor = vendorName.trimmingCharacters(in: .whitespaces)
        guard !cleanVendor.isEmpty else {
            errorMessage = "Please enter vendor or supplier name."
            return
        }

        let cleanPart = partDescription.trimmingCharacters(in: .whitespaces)
        guard !cleanPart.isEmpty else {
            errorMessage = "Please describe the purchased part."
            return
        }

        guard let price = Double(unitPriceString), price > 0 else {
            errorMessage = "Please enter a valid positive unit price."
            return
        }

        errorMessage = nil
        isSubmitting = true

        Task {
            let inv = invoiceNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : invoiceNumber.trimmingCharacters(in: .whitespaces)
            let success = await onSubmit(selectedWorkOrderId, cleanVendor, inv, price, quantity, cleanPart)
            isSubmitting = false
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to submit expense claim. Check network or local cache."
            }
        }
    }
}
