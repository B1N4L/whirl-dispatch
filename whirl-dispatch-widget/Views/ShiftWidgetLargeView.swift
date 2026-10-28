//
//  ShiftWidgetLargeView.swift
//  whirl-dispatch-widget
//
//  Created by Binal on 2026-10-28.
//

import SwiftUI
import WidgetKit
import AppIntents

struct ShiftWidgetLargeView: View {
    let snapshot: ShiftWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))

                    Text("WHIRLDISPATCH")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)

                    Text(statusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
            }

            // Timer Dial Card
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.isClockedIn ? "CURRENT ON-SITE SHIFT DURATION" : "SHIFT DURATION")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                if snapshot.isClockedIn, let clockIn = snapshot.clockInDate {
                    Text(clockIn, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                } else {
                    Text("00:00:00")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)

            // Active Work Order Card
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(snapshot.activeWorkOrderNumber ?? "STANDBY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))

                    Spacer()

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Text(snapshot.activeWorkOrderTitle ?? "No work order in progress")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(snapshot.activeFacilityName ?? "Standby for new commercial dispatch")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)

            // Metrics Summary Grid
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BREAK TIME")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(snapshot.formattedBreakTime)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY TOTAL")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(snapshot.formattedTodayHours)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 15/255, green: 43/255, blue: 72/255))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
            }

            Spacer(minLength: 0)

            // Interactive Buttons
            if !snapshot.isClockedIn {
                Button(intent: ClockInAppIntent()) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Clock In to Job Site")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color(red: 15/255, green: 43/255, blue: 72/255))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 10) {
                    Button(intent: ToggleBreakAppIntent()) {
                        HStack(spacing: 6) {
                            Image(systemName: snapshot.isOnBreak ? "play.fill" : "pause.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(snapshot.isOnBreak ? "Resume Shift" : "Take Break")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(snapshot.isOnBreak ? Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.15) : Color(red: 230/255, green: 81/255, blue: 0/255).opacity(0.15))
                        .foregroundColor(snapshot.isOnBreak ? Color(red: 46/255, green: 125/255, blue: 50/255) : Color(red: 230/255, green: 81/255, blue: 0/255))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(intent: ClockOutAppIntent()) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Clock Out")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color(red: 198/255, green: 40/255, blue: 40/255).opacity(0.15))
                        .foregroundColor(Color(red: 198/255, green: 40/255, blue: 40/255))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
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
