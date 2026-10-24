//
//  FacilityMapView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-24.
//

import SwiftUI
import MapKit

struct FacilityMapView: View {
    @State private var facilities: [Facility] = []
    @State private var selectedFacility: Facility? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyleSelection: Int = 0 // 0: standard, 1: hybrid
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let apiService = APIService.shared


    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // native swiftui map
                Map(position: $cameraPosition, selection: $selectedFacility) {
                    ForEach(facilities) { fac in
                        Annotation(fac.displayName, coordinate: fac.coordinate) {
                            facilityPin(fac)
                        }
                        .tag(fac)
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

                // bottom facility inspection card
                if let fac = selectedFacility {
                    facilityInspectionCard(fac)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Facility Fleet Map")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadFacilities()
            }
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


    // MARK: - Facility Inspection Card

    private func facilityInspectionCard(_ fac: Facility) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        .foregroundColor(Color.statusGreen)
                }
            }

            HStack(spacing: 12) {
                // call site contact
                Link(destination: URL(string: "tel:\(fac.contactPhone)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Call Site (\(fac.contactPersonName))")
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
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
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


    // MARK: - Helper Methods

    private func openInAppleMaps(_ fac: Facility) {
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
