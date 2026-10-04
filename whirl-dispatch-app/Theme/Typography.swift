//
//  Typography.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-04.
//

import SwiftUI

extension Font {
    // scaled fonts using dynamic type


    static let appTitle = Font.system(.title2, design: .default).weight(.bold)
    static let appSection = Font.system(.title3, design: .default).weight(.semibold)
    static let appHeadline = Font.system(.headline, design: .default)
    static let appSubheadline = Font.system(.subheadline, design: .default)

    static let appBody = Font.system(.body, design: .default)
    static let appCaption = Font.system(.caption, design: .default)
    static let appFootnote = Font.system(.footnote, design: .default)


    // monospaced font for work order ids, serials and timers
    static let appMono = Font.system(.body, design: .monospaced)
    static let appMonoHeadline = Font.system(.headline, design: .monospaced)
    static let appMonoCaption = Font.system(.caption, design: .monospaced)
}

struct TypographyPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WO-2026-4401").font(.appMonoHeadline)
            Text("Chiller Unit 4 Diagnostic").font(.appTitle)
            Text("Routine Maintenance").font(.appSubheadline).foregroundColor(.secondary)
            Text("Checking refrigerant levels in sub-basement.").font(.appBody)
        }
        .padding()
    }
}
