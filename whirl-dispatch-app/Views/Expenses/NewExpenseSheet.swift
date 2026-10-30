//
//  NewExpenseSheet.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-22.
//

import SwiftUI
import UIKit

struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    var workOrderId: String
    var onSubmit: (String, String, String?, Double, Int, String, PartCategory) async -> String?

    @State private var vendorName: String = ""
    @State private var invoiceNumber: String = ""
    @State private var selectedCategory: PartCategory = .hardware
    @State private var partDescription: String = ""
    @State private var quantity: Int = 1
    @State private var unitPriceString: String = ""

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    private let expenseThreshold: Double = 250.0


    // live calculated subtotal
    private var calculatedTotal: Double {
        let price = AppCurrency.sanitizePriceInput(unitPriceString)
        return Double(quantity) * price
    }

    // currency formatted string using standard number formatter
    private var formattedTotal: String {
        AppCurrency.format(calculatedTotal)
    }


    var body: some View {
        NavigationStack {
          Form {
              // section 1: vendor and receipt
              Section(header: Text("Supply House & Receipt")) {
                  TextField("Store / Vendor Name", text: $vendorName)
                      .textInputAutocapitalization(.words)

                  TextField("Invoice / Receipt # (optional)", text: $invoiceNumber)
                      .textInputAutocapitalization(.characters)
              }


              // section 3: category picker chips
              Section(header: Text("Part Category")) {
                  ScrollView(.horizontal, showsIndicators: false) {
                      HStack(spacing: 8) {
                          ForEach(PartCategory.allCases) { cat in
                              categoryChip(cat)
                          }
                      }
                      .padding(.vertical, 4)
                  }
              }


              // section 4: parts detail & live total
              Section(header: Text("Emergency Part Details")) {
                  TextField("Part Description (e.g. Contactor 30A 24V Coil)", text: $partDescription)

                  Stepper(value: $quantity, in: 1...99) {
                     HStack {
                         Text("Quantity")
                         Spacer()
                         Text("\(quantity)")
                             .fontWeight(.semibold)
                     }
                  }

                  HStack {
                      Text("Unit Price (LKR)")
                      Spacer()
                      TextField("0.00", text: $unitPriceString)
                          .keyboardType(.decimalPad)
                          .multilineTextAlignment(.trailing)
                          .frame(width: 120)
                  }

                  // formatted total row
                  HStack {
                      Text("Estimated Subtotal")
                          .font(.appSubheadline)
                          .foregroundColor(.secondary)
                      Spacer()
                      Text(formattedTotal)
                          .font(.appHeadline)
                          .foregroundColor(calculatedTotal > expenseThreshold ? Color.statusAmber : Color.brandNavy)
                  }
                  .padding(.top, 2)
              }


              // threshold warning alert if total exceeds $250
              if calculatedTotal > expenseThreshold {
                  Section {
                      HStack(alignment: .top, spacing: 10) {
                          Image(systemName: "exclamationmark.shield.fill")
                              .font(.system(size: 20))
                              .foregroundColor(Color.statusAmber)

                          VStack(alignment: .leading, spacing: 3) {
                              Text("Optical Inspection Required")
                                  .font(.appSubheadline)
                                  .fontWeight(.semibold)
                                  .foregroundColor(Color.statusAmber)

                              Text("Claims exceeding LKR 250.00 require supervisor review before customer invoice generation.")
                                  .font(.appCaption)
                                  .foregroundColor(.secondary)
                          }
                      }
                      .padding(.vertical, 2)
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
        }
    }


    @ViewBuilder
    private func categoryChip(_ cat: PartCategory) -> some View {
        let isSelected = selectedCategory == cat

        Button(action: {
            selectedCategory = cat
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            HStack(spacing: 6) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 13))
                Text(cat.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brandNavy : Color(uiColor: .secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandNavy : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }


    private func submitForm() {
        guard !workOrderId.isEmpty else {
            errorMessage = "No active work order dispatch available."
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

        let price = AppCurrency.sanitizePriceInput(unitPriceString)
        guard price > 0 else {
            errorMessage = "Please enter a valid positive unit price."
            return
        }

        errorMessage = nil
        isSubmitting = true

        Task {
            let inv = invoiceNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : invoiceNumber.trimmingCharacters(in: .whitespaces)
            let failureReason = await onSubmit(workOrderId, cleanVendor, inv, price, quantity, cleanPart, selectedCategory)
            isSubmitting = false
            if let failureReason = failureReason {
                errorMessage = failureReason
            } else {
                dismiss()
            }
        }
    }
}
