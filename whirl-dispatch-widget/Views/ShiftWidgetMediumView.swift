//
//  ShiftWidgetMediumView.swift
//  whirl-dispatch-widget
//
//  Created by Binal on 2026-10-28.
//

import SwiftUI
import WidgetKit
import AppIntents

struct ShiftWidgetMediumView: View {
    let snapshot: ShiftWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Bar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))

                    Text("WHIRLDISPATCH")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))
                }

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(statusText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
            }

            // Middle Shift Stats
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    if snapshot.isClockedIn, let clockIn = snapshot.clockInDate {
                        Text(clockIn, style: .timer)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    } else {
                        Text("00:00:00")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Text(snapshot.activeFacilityName ?? "No Assigned Facility")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Summary chips
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("Break:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(snapshot.formattedBreakTime)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 4) {
                        Text("Today:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(snapshot.formattedTodayHours)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))
                    }
                }
            }

            Spacer(minLength: 0)

            // Interactive Buttons
            if !snapshot.isClockedIn {
                Button(intent: ClockInAppIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Clock In to Job Site")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color(red: 15/255, green: 43/255, blue: 72/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    Button(intent: ToggleBreakAppIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: snapshot.isOnBreak ? "play.fill" : "pause.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(snapshot.isOnBreak ? "Resume" : "Take Break")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(snapshot.isOnBreak ? Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.15) : Color(red: 230/255, green: 81/255, blue: 0/255).opacity(0.15))
                        .foregroundColor(snapshot.isOnBreak ? Color(red: 46/255, green: 125/255, blue: 50/255) : Color(red: 230/255, green: 81/255, blue: 0/255))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(intent: ClockOutAppIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Clock Out")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color(red: 198/255, green: 40/255, blue: 40/255).opacity(0.15))
                        .foregroundColor(Color(red: 198/255, green: 40/255, blue: 40/255))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
    }

    private var statusColor: Color {
        if !snapshot.isClockedIn {
            return .secondary
        }
        return snapshot.isOnBreak ? Color(red: 230/255, green: 81/255, blue: 0/255) : Color(red: 46/255, green: 125/255, blue: 50/255)
    }

    private var statusText: String {
        if !snapshot.isClockedIn {
            return "OFF DUTY"
        }
        return snapshot.isOnBreak ? "ON BREAK" : "ON SITE"
    }
}
