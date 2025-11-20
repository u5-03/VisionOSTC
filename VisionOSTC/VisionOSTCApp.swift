//
//  VisionOSTCApp.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import SwiftUI

@main
struct VisionOSTCApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }

        // Portal用のWindow（XY平面に表示）
        WindowGroup(id: "PortalWindow") {
            PortalWindowView()
                .environment(appModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 800, height: 800)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
