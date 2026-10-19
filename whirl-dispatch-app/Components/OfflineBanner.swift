//
//  OfflineBanner.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-14.
//

import SwiftUI

struct OfflineBanner: View {
    var isOffline: Bool = true
    var pendingCount: Int = 0
    var onSync: (() -> Void)? = nil


    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isOffline ? "wifi.slash" : "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isOffline ? Color.statusAmber : Color.accentBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(isOffline ? "Offline Mode (Shielded Plant Room)" : "Back Online")
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if pendingCount > 0 {
                    Text("\(pendingCount) changes queued locally for sync")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Serving cached data from device")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()


            if pendingCount > 0, let onSync = onSync {
                Button(action: onSync) {
                    Text(isOffline ? "Sync Queued" : "Sync Now")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isOffline ? Color.statusAmber : Color.accentBlue)
                        )
                }
                .accessibilityLabel("Sync queued changes to server")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isOffline ? Color.statusAmber.opacity(0.12) : Color.accentBlue.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isOffline ? Color.statusAmber.opacity(0.3) : Color.accentBlue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}


#Preview {
    VStack(spacing: 12) {
        OfflineBanner(isOffline: true, pendingCount: 3)
        OfflineBanner(isOffline: false, pendingCount: 2) {}
    }
}
