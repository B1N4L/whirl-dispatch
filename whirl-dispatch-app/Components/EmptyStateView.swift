//
//  EmptyStateView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-05.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil


    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            VStack(spacing: 6) {
                Text(title)
                    .font(.appHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }


            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.brandNavy.opacity(0.12))
                        )
                        .foregroundColor(Color.brandNavy)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}


#Preview {
    EmptyStateView(
        icon: "clipboard.fill",
        title: "No Dispatches Available",
        message: "You currently have no assigned work orders for this shift.",
        actionTitle: "Refresh List"
    ) {}
}
