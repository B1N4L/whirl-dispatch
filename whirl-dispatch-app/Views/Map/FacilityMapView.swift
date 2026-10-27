//
//  FacilityMapView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-24.
//

import SwiftUI
import MapKit

struct FacilityMapView: View {
    var trackedSites: [TrackedSite] = []
    @Binding var selectedTrackedSite: TrackedSite?

    @State private var facilities: [Facility] = []
    @State private var selectedFacility: Facility? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyleSelection: Int = 0 // 0: standard, 1: hybrid
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let apiService = APIService.shared
    private let locationManager = LocationManager.shared
    private let geofenceService = GeofenceService.shared

    init(
        trackedSites: [TrackedSite] = [],
        selectedTrackedSite: Binding<TrackedSite?> = .constant(nil)
    ) {
        self.trackedSites = trackedSites
        self._selectedTrackedSite = selectedTrackedSite
    }


    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // native swiftui map with geofence circular overlays and team markers
                Map(position: $cameraPosition) {
                    if !trackedSites.isEmpty {
                        ForEach(trackedSites) { site in
                            // circular geofence boundary around facility
                            MapCircle(center: site.facility.coordinate, radius: site.facility.geofenceRadius)
                                .foregroundStyle((site.isEmergency ? Color.red : (site.isOnSite ? Color.statusGreen : Color.accentBlue)).opacity(0.18))
                                .stroke((site.isEmergency ? Color.red : (site.isOnSite ? Color.statusGreen : Color.accentBlue)).opacity(0.7), lineWidth: 2)

                            // facility site pin
                            Annotation(site.facility.facilityName, coordinate: site.facility.coordinate) {
                                trackedFacilityPin(site)
                            }

                            // live technician team or vehicle marker
                            Annotation(site.team.leadTechnician?.fullName ?? "Field Crew", coordinate: site.telemetry.coordinate) {
                                trackedTeamMarker(site)
                            }
                        }
                    } else {
                        // fallback to standard facilities if no live tracked sites
                        ForEach(facilities) { fac in
                            MapCircle(center: fac.coordinate, radius: fac.geofenceRadius)
                                .foregroundStyle(Color.accentBlue.opacity(0.18))
                                .stroke(Color.accentBlue.opacity(0.7), lineWidth: 2)

                            Annotation(fac.displayName, coordinate: fac.coordinate) {
                                facilityPin(fac)
                            }
                            .tag(fac)
                        }
                    }

                    // supervisor local device location marker
                    Annotation("My Location", coordinate: locationManager.effectiveCoordinate) {
                        technicianLiveMarker
                    }
                }
                .mapStyle(mapStyleSelection == 0 ? .standard(elevation: .realistic) : .hybrid(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }

                // top map style picker overlay
                VStack {
                    HStack {
                        Picker("Map Style", selection: $mapStyleSelection) {
                            Text("Standard").tag(0)
                            Text("Satellite").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.top, 8)
                        .padding(.leading, 16)

                        Spacer()

                        // refresh button
                        Button(action: {
                            Task {
                                await loadFacilities()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }

                // bottom inspection card: tracked site or fallback facility
                if let site = selectedTrackedSite {
                    trackedSiteInspectionCard(site)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                } else if let fac = selectedFacility {
                    facilityInspectionCard(fac)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Live Fleet & Site Map")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                locationManager.startUpdating()
                if trackedSites.isEmpty {
                    await loadFacilities()
                } else {
                    focusInitialTrackedSite()
                }
            }
            .onChange(of: selectedTrackedSite) { _, newSite in
                if let site = newSite {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: site.telemetry.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                            )
                        )
                    }
                }
            }
        }
    }


    // MARK: - Tracked Site Annotations

    private func trackedFacilityPin(_ site: TrackedSite) -> some View {
        let isSelected = selectedTrackedSite?.id == site.id

        return VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.brandNavy : (site.isEmergency ? Color.red : Color.accentBlue))
                    .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

                Image(systemName: "building.2.fill")
                    .font(.system(size: isSelected ? 17 : 14))
                    .foregroundColor(.white)
            }

            Image(systemName: "triangle.fill")
                .font(.system(size: 9))
                .foregroundColor(isSelected ? Color.brandNavy : (site.isEmergency ? Color.red : Color.accentBlue))
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                selectedTrackedSite = site
            }
        }
    }

    private func trackedTeamMarker(_ site: TrackedSite) -> some View {
        let isSelected = selectedTrackedSite?.id == site.id

        return VStack(spacing: 2) {
            HStack(spacing: 4) {
                if site.isOnSite {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11))
                    Text(site.team.leadTechnician?.initials ?? "ON-SITE")
                        .font(.system(size: 10, weight: .bold))
                } else if site.isEnRoute {
                    Image(systemName: "car.fill")
                        .font(.system(size: 11))
                    Text(site.vehicle?.licensePlate ?? "EN ROUTE")
                        .font(.system(size: 10, weight: .bold))
                } else {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text(site.team.leadTechnician?.initials ?? "DISPATCH")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(site.isOnSite ? Color.statusGreen : (site.isEnRoute ? Color.accentBlue : Color.statusAmber))
            )
            .foregroundColor(.white)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.15 : 1.0)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                selectedTrackedSite = site
            }
        }
    }


    // MARK: - Tracked Site Inspection Card

    private func trackedSiteInspectionCard(_ site: TrackedSite) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(site.workOrderNumber)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.accentBlue)

                        Text(site.status.label)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (site.isOnSite ? Color.statusGreen : (site.isEnRoute ? Color.accentBlue : Color.statusAmber)).opacity(0.15)
                            )
                            .foregroundColor(site.isOnSite ? Color.statusGreen : (site.isEnRoute ? Color.accentBlue : Color.statusAmber))
                            .clipShape(Capsule())

                        if site.isEmergency {
                            Text("EMERGENCY")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(Color.red)
                                .clipShape(Capsule())
                        }
                    }

                    Text(site.facility.facilityName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)

                    Text(site.facility.companyName)
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        selectedTrackedSite = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }

            // telemetry location and geofence status
            HStack(spacing: 8) {
                Image(systemName: site.telemetry.isInsideGeofence ? "checkmark.shield.fill" : "location.north.circle.fill")
                    .font(.system(size: 12))
                Text(site.telemetry.isInsideGeofence ? "Within Plant Room Geofence (\(site.telemetry.formattedDistance))" : "Transit Distance to Facility: \(site.telemetry.formattedDistance)")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(site.telemetry.isInsideGeofence ? Color.statusGreen : Color.accentBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((site.telemetry.isInsideGeofence ? Color.statusGreen : Color.accentBlue).opacity(0.12))
            .cornerRadius(6)

            Divider()

            // team and vehicle details
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DEPLOYED CREW")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)

                    Text(site.team.leadTechnician?.fullName ?? "Unassigned")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("\(site.team.totalHeadcount) total technicians")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("ASSIGNED FLEET ASSET")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)

                    if let veh = site.vehicle {
                        Text(veh.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(veh.licensePlate)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.accentBlue)
                    } else {
                        Text("No Fleet Vehicle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // action buttons: call lead technician and directions
            HStack(spacing: 10) {
                if let phone = site.team.leadTechnician?.phone, let phoneURL = URL(string: "tel:\(phone)") {
                    Link(destination: phoneURL) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                            Text("Call Lead Tech")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brandNavy)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                Button(action: {
                    openInAppleMaps(site.facility)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(.ultraThickMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private func focusInitialTrackedSite() {
        if let first = selectedTrackedSite ?? trackedSites.first {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: first.telemetry.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }





    // MARK: - Annotation Views

    private func facilityPin(_ fac: Facility) -> some View {
        let isSelected = selectedFacility?.id == fac.id

        return VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.brandNavy : Color.accentBlue)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: "building.2.fill")
                    .font(.system(size: isSelected ? 18 : 15))
                    .foregroundColor(.white)
            }

            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(isSelected ? Color.brandNavy : Color.accentBlue)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                selectedFacility = fac
            }
        }
    }

    private var technicianLiveMarker: some View {
        ZStack {
            Circle()
                .fill(Color.statusGreen.opacity(0.25))
                .frame(width: 32, height: 32)
            Circle()
                .fill(Color.statusGreen)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }


    // MARK: - Facility Inspection Card with Geofence Status

    private func facilityInspectionCard(_ fac: Facility) -> some View {
        let eval = geofenceService.evaluate(
            userCoordinate: locationManager.effectiveCoordinate,
            facilityCoordinate: fac.coordinate,
            radiusMeters: fac.geofenceRadius
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fac.companyName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.accentBlue)

                    Text(fac.facilityName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(fac.address)
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        selectedFacility = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }

            // geofence status callout badge
            HStack(spacing: 8) {
                Image(systemName: eval.isInside ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                Text(eval.isInside ? "Within Geofence Perimeter (\(eval.formattedDistance))" : "Outside Geofence (\(eval.formattedDistance) away)")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(eval.isInside ? Color.statusGreen : Color.statusAmber)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(eval.isInside ? Color.statusGreen.opacity(0.12) : Color.statusAmber.opacity(0.12))
            .cornerRadius(6)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Plant Room SLA")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(fac.slaResponseHours ?? 4)h Target Response")
                        .font(.system(size: 12, weight: .semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Geofence Radius")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(Int(fac.geofenceRadius))m Perimeter")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accentBlue)
                }
            }

            // action buttons
            HStack(spacing: 10) {
                // call site contact
                Link(destination: URL(string: "tel:\(fac.contactPhone)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Call Site")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.brandNavy)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // open native apple maps directions
                Button(action: {
                    openInAppleMaps(fac)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }

                // simulator testing toggle
                Button(action: {
                    if locationManager.isSimulatedLocationActive {
                        locationManager.resetSimulation()
                    } else {
                        locationManager.simulateArrival(at: fac.coordinate)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: locationManager.isSimulatedLocationActive ? "location.slash.fill" : "location.north.circle.fill")
                        Text(locationManager.isSimulatedLocationActive ? "Reset GPS" : "Simulate")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .foregroundColor(locationManager.isSimulatedLocationActive ? Color.statusAmber : Color.brandNavy)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(.ultraThickMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }


    // MARK: - Helper Methods

    private func openInAppleMaps(_ fac: Facility) {
        if let url = URL(string: "http://maps.apple.com/?daddr=\(fac.latitude),\(fac.longitude)&dirflg=d") {
            UIApplication.shared.open(url)
        }
    }

    private func openInAppleMaps(_ fac: TrackedFacility) {
        if let url = URL(string: "http://maps.apple.com/?daddr=\(fac.latitude),\(fac.longitude)&dirflg=d") {
            UIApplication.shared.open(url)
        }
    }


    private func loadFacilities() async {
        isLoading = true
        errorMessage = nil

        do {
            let res: FacilityListResponse = try await apiService.send(.getFacilities)
            if !res.facilities.isEmpty {
                self.facilities = res.facilities
                updateCameraPosition()
                isLoading = false
                return
            }
        } catch {
            // fall back to default commercial facilities if network unready
        }

        // sample commercial plant rooms matching coursework dispatches
        self.facilities = [
            Facility(
                id: "fac-01",
                companyName: "Metro Commercial Group",
                facilityName: "Metro Commercial Center HQ",
                address: "452 Galle Road, Colombo 03",
                latitude: 6.9271,
                longitude: 79.8612,
                geofenceRadius: 150.0,
                contactPersonName: "Rohan De Silva",
                contactPhone: "+94 11 234 5678",
                contactEmail: "rohan@metrocommercial.lk",
                slaResponseHours: 2,
                contractHourlyRate: "85.00",
                partsMarkupPercent: "25.00"
            ),
            Facility(
                id: "fac-02",
                companyName: "Apex Healthcare Ltd",
                facilityName: "Apex Healthcare Tower",
                address: "88 Ward Place, Colombo 07",
                latitude: 6.9147,
                longitude: 79.8732,
                geofenceRadius: 150.0,
                contactPersonName: "Dr. K. Bandara",
                contactPhone: "+94 11 876 5432",
                contactEmail: "facilities@apexhealth.lk",
                slaResponseHours: 1,
                contractHourlyRate: "95.00",
                partsMarkupPercent: "30.00"
            ),
            Facility(
                id: "fac-03",
                companyName: "North Central Tech",
                facilityName: "Regional Data Center",
                address: "12 Kandy Road, Kelaniya",
                latitude: 6.9534,
                longitude: 79.9189,
                geofenceRadius: 200.0,
                contactPersonName: "Saman Perera",
                contactPhone: "+94 11 555 8989",
                contactEmail: "saman@nctech.lk",
                slaResponseHours: 4,
                contractHourlyRate: "80.00",
                partsMarkupPercent: "20.00"
            )
        ]

        updateCameraPosition()
        isLoading = false
    }

    private func updateCameraPosition() {
        guard let first = facilities.first else { return }
        cameraPosition = .region(
            MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }
}


#Preview {
    FacilityMapView()
}
