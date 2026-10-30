//
//  AppCurrency.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-30.
//

import Foundation

enum AppCurrency {
    static let code = "LKR"
    static let symbol = "LKR "

    static func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numStr = formatter.string(from: NSNumber(value: abs(value))) ?? String(format: "%.2f", abs(value))
        if value < 0 {
            return "-LKR \(numStr)"
        }
        return "LKR \(numStr)"
    }

    static func format(stringVal: String) -> String {
        if let val = Double(stringVal) {
            return format(val)
        }
        return "LKR \(stringVal)"
    }

    static func formatRate(_ rate: Double) -> String {
        "\(format(rate))/hr"
    }

    static func formatRate(stringVal: String) -> String {
        if let val = Double(stringVal) {
            return formatRate(val)
        }
        return "LKR \(stringVal)/hr"
    }

    static func formatCompact(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absVal = abs(value)
        if absVal >= 1_000_000 {
            return String(format: "%@LKR %.1fM", sign, absVal / 1_000_000.0)
        } else if absVal >= 1_000 {
            return String(format: "%@LKR %.1fk", sign, absVal / 1_000.0)
        }
        return String(format: "%@LKR %.0f", sign, absVal)
    }

    static func sanitizePriceInput(_ input: String) -> Double {
        let clean = input
            .replacingOccurrences(of: "LKR", with: "")
            .replacingOccurrences(of: "lkr", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "rs.", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(clean) ?? 0.0
    }
}
