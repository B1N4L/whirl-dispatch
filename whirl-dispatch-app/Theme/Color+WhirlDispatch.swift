//
//  Color+WhirlDispatch.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-04.
//

import SwiftUI

extension Color {
    // brand colors for hvac theme
    static let brandNavy = Color(hex: "0F2B48")
    static let brandNavyDark = Color(hex: "091A2C")
    static let accentBlue = Color(hex: "1E88E5")
    static let accentBlueLight = Color(hex: "64B5F6")


    // status colors
    static let statusGreen = Color(hex: "2E7D32")
    static let statusAmber = Color(hex: "E65100")
    static let statusRed = Color(hex: "C62828")
    static let statusGray = Color(hex: "757575")

    // backgrounds for cards and rows
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let plantRoomSlate = Color(hex: "263238")
    static let surfaceBorder = Color(UIColor.separator)


    // helper initializer for hex color strings
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var intVal: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&intVal)

        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // 12-bit
            (a, r, g, b) = (255, (intVal >> 8) * 17, (intVal >> 4 & 0xF) * 17, (intVal & 0xF) * 17)
        case 6: // 24-bit
            (a, r, g, b) = (255, intVal >> 16, intVal >> 8 & 0xFF, intVal & 0xFF)
        case 8: // 32-bit
            (a, r, g, b) = (intVal >> 24, intVal >> 16 & 0xFF, intVal >> 8 & 0xFF, intVal & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
