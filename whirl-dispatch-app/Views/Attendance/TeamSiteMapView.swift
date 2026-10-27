//
//  TeamSiteMapView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-28.
//

import SwiftUI
import MapKit

struct TeamSiteMapView: View {
    let workOrderId: String
    @Environment(\.dismiss) private var dismiss

    @State private var telemetry: TeamSiteTelemetryResponse? = nil
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var selectedMember: TeamMemberTelemetry? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyleSelection: Int = 0 // 0: Standard, 1: Hybrid

    private let apiService = APIService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map Area
                if let data = telemetry {
                    Map(position: $cameraPosition) {
                        // Geofence Circle
                        MapCircle(center: data.facility.coordinate, radius: data.facility.geofenceRadius)
                            .foregroundStyle(Color.statusGreen.opacity(0.15))
                            .stroke(Color.statusGreen, lineWidth: 2)

                        // Facility Center Marker
                        Annotation(data.facility.facilityName, coordinate: data.facility.coordinate) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandNavy)
                                        .frame(width: 38, height: 38)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                                    Image(systemName: "building.2.crop.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }

                                Text(data.facility.facilityName)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.9))
                                    .foregroundColor(Color.brandNavy)
                                    .cornerRadius(4)
                                    .shadow(radius: 1)
                            }
                        }

                        // Team Member Markers
                        ForEach(data.team) { member in
                            Annotation(member.fullName, coordinate: member.coordinate) {
                                memberMarker(member: member)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedMember = member
                                        }
                                    }
                            }
                        }
                    }
                    .mapStyle(mapStyleSelection == 0 ? .standard : .hybrid(elevation: .realistic))
                    .ignoresSafeArea(edges: .bottom)
                } else if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Team Telemetry...")
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.statusAmber)
                        Text("Unable to Load Team")
                            .font(.appHeadline)
                        Text(error)
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Button("Try Again") {
                            Task {
                                await loadTelemetry()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandNavy)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Top Floating Telemetry Header
                if let data = telemetry {
                    VStack {
                        topTelemetryBar(data: data)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        Spacer()
                    }

                    // Bottom Floating Roster Card
                    bottomRosterSheet(data: data)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle(telemetry?.workOrderNumber ?? "Team Site Telemetry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    // Map Style Toggle
                    Picker("Map Style", selection: $mapStyleSelection) {
                        Text("Map").tag(0)
                        Text("Satellite").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)

                    // Refresh Button
                    Button(action: {
                        Task {
                            await loadTelemetry()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadTelemetry()
            }
        }
    }

    // MARK: - Subviews & Controls

    @ViewBuilder
    private func topTelemetryBar(data: TeamSiteTelemetryResponse) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.facility.companyName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(data.facility.facilityName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(Color.statusGreen)
                    .font(.caption)

                Text("\(data.insideGeofenceCount)/\(data.totalCrewCount) On-Site")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.statusGreen)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.statusGreen.opacity(0.12))
            .cornerRadius(6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.95))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private func memberMarker(member: TeamMemberTelemetry) -> some View {
        let isSelected = selectedMember?.id == member.id
        let ringColor: Color = member.isClockedIn
            ? (member.isInsideGeofence ? Color.statusGreen : Color.statusAmber)
            : Color.secondary

        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(member.isLead ? Color.brandNavy : Color.accentBlue)
                    .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)
                    .overlay(
                        Circle()
                            .stroke(ringColor, lineWidth: 3)
                    )
                    .shadow(color: ringColor.opacity(0.4), radius: 4, x: 0, y: 2)

                if member.isLead {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                } else {
                    Text(member.initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Text(member.fullName.components(separatedBy: " ").first ?? member.fullName)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.92))
                .foregroundColor(.primary)
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }

    @ViewBuilder
    private func bottomRosterSheet(data: TeamSiteTelemetryResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Assigned Crew Roster")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(data.facility.geofenceRadius, specifier: "%.0f")m Geofence Perimeter")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(data.team) { member in
                        memberRosterCard(member: member)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.96))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func memberRosterCard(member: TeamMemberTelemetry) -> some View {
        let isSelected = selectedMember?.id == member.id
        let statusColor: Color = member.isClockedIn
            ? (member.isInsideGeofence ? Color.statusGreen : Color.statusAmber)
            : Color.secondary

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(member.isLead ? Color.brandNavy : Color.accentBlue)
                        .frame(width: 28, height: 28)

                    Text(member.initials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(member.fullName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if member.isLead {
                            Text("Lead")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.brandNavy)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.brandNavy.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }

                    Text(member.statusDisplayTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(statusColor)
                }
            }

            HStack {
                Text(member.isInsideGeofence ? "Inside (\(member.formattedDistance))" : "\(member.formattedDistance) away")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if let phone = member.phone, !phone.isEmpty {
                    if let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })") {
                        Link(destination: url) {
                            HStack(spacing: 3) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 9))
                                Text("Call")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.statusGreen.opacity(0.14))
                            .foregroundColor(Color.statusGreen)
                            .cornerRadius(5)
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 210)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.brandNavy : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                selectedMember = member
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: member.coordinate,
                        latitudinalMeters: 400,
                        longitudinalMeters: 400
                    )
                )
            }
        }
    }

    // MARK: - Telemetry Fetch

    private func loadTelemetry() async {
        isLoading = true
        errorMessage = nil

        do {
            let res: TeamSiteTelemetryResponse = try await apiService.send(.getTeamTelemetry(workOrderId: workOrderId))
            telemetry = res

            // Center camera to encompass facility and its geofence
            let radiusSpan = max(500, res.facility.geofenceRadius * 3.5)
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: res.facility.coordinate,
                    latitudinalMeters: radiusSpan,
                    longitudinalMeters: radiusSpan
                )
            )
            isLoading = false
        } catch let apiErr as APIError {
            isLoading = false
            errorMessage = apiErr.localizedDescription
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
