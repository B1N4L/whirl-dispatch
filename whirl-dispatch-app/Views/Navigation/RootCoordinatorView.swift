//
//  RootCoordinatorView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-15.
//

import SwiftUI

@MainActor
struct RootCoordinatorView: View {
    @State private var authVM = AuthViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if !authVM.isAuthenticated || authVM.currentUser == nil {
                LoginView(viewModel: authVM)
            } else {
                switch authVM.currentUser!.role {
                case .technician, .leadTechnician:
                    // iphone compact tab navigation for field and lead technicians
                    FieldTechTabView(authVM: authVM)

                case .supervisor:
                    if horizontalSizeClass == .regular {
                        // ipad command center three-column split view
                        SupervisorSplitView(authVM: authVM)
                    } else {
                        // compact fallback for supervisor on iphone
                        SupervisorCompactView(authVM: authVM)
                    }

                case .paymentClerk:
                    if horizontalSizeClass == .regular {
                        // ipad billing center split view
                        ClerkSplitView(authVM: authVM)
                    } else {
                        // compact fallback for billing clerk on iphone
                        ClerkCompactView(authVM: authVM)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authVM.isAuthenticated)
    }
}
