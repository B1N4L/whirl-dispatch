//
//  ErrorBanner.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-05.
//

import SwiftUI

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil


    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.statusRed)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Attention")
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.statusRed)

                Text(message)
                    .font(.appCaption)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)


            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(6)
                }
                .accessibilityLabel("Dismiss Alert")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.statusRed.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.statusRed.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}


#Preview {
    VStack {
        ErrorBanner(message: "Failed to connect to backend server. Operating in offline mode.") {}
        Spacer()
    }
    .padding(.top)
}
