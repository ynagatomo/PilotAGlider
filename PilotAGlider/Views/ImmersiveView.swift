//
//  ImmersiveView.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/15.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var eventSubscription: EventSubscription?

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let rootEntity = try? await Entity(named: "Flight", in: realityKitContentBundle) {
                rootEntity.position = .init(x: 0, y: 0.7, z: 0)

                appModel.setupFlyingScene(rootEntity)

                eventSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                    appModel.gameLoop(event.deltaTime)
                } // subscription
                content.add(rootEntity)
            } else {
                assertionFailure()
            }
        } // RealityView
        .handlesGameControllerEvents(matching: .gamepad)
        .onDisappear {
            eventSubscription?.cancel() // fail-safe
            eventSubscription = nil
        }
    } // body
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
