//
//  WorkOrderListView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-18.
//

import SwiftUI

struct WorkOrderListView: View {
    @State private var viewModel = WorkOrdersViewModel()
    @State private var networkMonitor = NetworkMonitor.shared


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // show offline bar if network unreachable
                if viewModel.isOffline || !networkMonitor.isConnected {
                    OfflineBanner(
                        isOffline: true,
                        pendingCount: 0
                    ) {
                        Task {
                            await viewModel.loadWorkOrders()
                        }
                    }
                }

                // filter chip selection row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WorkOrderFilter.allCases) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                count: viewModel.count(for: filter),
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(UIColor.systemBackground))


                // work order items list or empty state placeholder
                if viewModel.isLoading && viewModel.workOrders.isEmpty {
                    Spacer()
                    ProgressView("Loading dispatches...")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if viewModel.filteredWorkOrders.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "clipboard",
                        title: "No Work Orders Found",
                        message: viewModel.searchQuery.isEmpty ? "No assigned work orders match this category." : "No results for \"\(viewModel.searchQuery)\".",
                        actionTitle: "Refresh Feed"
                    ) {
                        Task {
                            await viewModel.loadWorkOrders()
                        }
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredWorkOrders) { order in
                            NavigationLink(destination: WorkOrderDetailView(order: order, viewModel: viewModel)) {
                                WorkOrderCardView(order: order)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadWorkOrders()
                    }
                }
            }
            .navigationTitle("Dispatches")
            .searchable(text: $viewModel.searchQuery, prompt: "Search work orders, facilities, chiller...")
            .task {
                if viewModel.workOrders.isEmpty {
                    await viewModel.loadWorkOrders()
                }
            }
        }
    }
}
