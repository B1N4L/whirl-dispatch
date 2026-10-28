//
//  ClockDialButton.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-20.
//

import SwiftUI
import UIKit

struct ClockDialButton: View {
    let isClockedIn: Bool
    let isOnBreak: Bool
    let timeText: String
    let isLoading: Bool
    var hasAssignedDispatch: Bool = true
    let action: () -> Void

    @State private var isPulsing = false


    var body: some View {
        Button(action: {
            guard !isLoading && (isClockedIn || hasAssignedDispatch) else { return }

            // heavy haptic feedback on clocking transition
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()

            action()
        }) {
            ZStack {
                // outer pulsating ring when active on site
                if isClockedIn {
                    Circle()
                        .stroke(
                            isOnBreak ? Color.statusAmber.opacity(0.3) : Color.statusGreen.opacity(0.3),
                            lineWidth: 12
                        )
                        .scaleEffect(isPulsing ? 1.08 : 1.0)
                        .opacity(isPulsing ? 0.6 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }

                // primary solid dial body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isClockedIn
                                ? (isOnBreak ? [Color(hex: "BF360C"), Color.statusAmber] : [Color(hex: "1B5E20"), Color.statusGreen])
                                : (hasAssignedDispatch ? [Color.brandNavyDark, Color.brandNavy] : [Color(hex: "455A64"), Color(hex: "607D8B")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 210, height: 210)
                    .shadow(
                        color: isClockedIn ? (isOnBreak ? Color.statusAmber.opacity(0.4) : Color.statusGreen.opacity(0.4)) : (hasAssignedDispatch ? Color.brandNavy.opacity(0.35) : Color(hex: "455A64").opacity(0.25)),
                        radius: 14,
                        x: 0,
                        y: 8
                    )

                // dial center content
                VStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    } else if isClockedIn {
                        Image(systemName: isOnBreak ? "pause.circle.fill" : "bolt.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.9))

                        Text(timeText)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text(isOnBreak ? "BREAK PAUSED" : "ACTIVE ON-SITE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.0)

                        Text("TAP TO CLOCK OUT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.top, 4)
                    } else if !hasAssignedDispatch {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 38))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.bottom, 2)

                        Text("STANDBY")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1.0)

                        Text("No Dispatch Assigned")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                            .padding(.bottom, 2)

                        Text("TAP TO CLOCK IN")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1.0)

                        Text("Plant Room Arrival")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: 230, height: 230)
        }
        .disabled(isLoading || (!isClockedIn && !hasAssignedDispatch))
        .accessibilityLabel(!hasAssignedDispatch ? "Standby. No dispatch assigned" : (isClockedIn ? "Clock out. Elapsed time \(timeText)" : "Clock in to site shift"))
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if isClockedIn {
                isPulsing = true
            }
        }
        .onChange(of: isClockedIn) { _, active in
            isPulsing = active
        }
    }
}


#Preview {
    VStack(spacing: 30) {
        ClockDialButton(isClockedIn: false, isOnBreak: false, timeText: "00:00:00", isLoading: false, hasAssignedDispatch: true) {}
        ClockDialButton(isClockedIn: false, isOnBreak: false, timeText: "00:00:00", isLoading: false, hasAssignedDispatch: false) {}
        ClockDialButton(isClockedIn: true, isOnBreak: false, timeText: "02:15:42", isLoading: false, hasAssignedDispatch: true) {}
    }
}
