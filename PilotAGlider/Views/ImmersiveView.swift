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
    @AppStorage(Constants.appStorageKeyOffset) var offset: Double = 0
    @State private var eventSubscription: EventSubscription?

    var body: some View {
        RealityView { content in
            if let rootEntity = try? await Entity(named: "Flight", in: realityKitContentBundle) {
                // dumpRealityEntity(rootEntity)
                rootEntity.position = .init(x: 0, y: 0.7, z: 0)

                appModel.setupFlyingScene(rootEntity)
                appModel.setBaseOffset(Float(offset))

                eventSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                    appModel.gameLoop(event.deltaTime)
                } // subscription
                content.add(rootEntity)
            } else {
                assertionFailure()
            }
        } // RealityView
        // .gesture(dragGesture)
        .handlesGameControllerEvents(matching: .gamepad)
        .onDisappear {
            eventSubscription?.cancel() // fail-safe
            eventSubscription = nil
        }
    } // body

    //    private var dragGesture: some Gesture {
    //        DragGesture()
    //            .targetedToAnyEntity()
    //            .onChanged { value in
    //                value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
    //            }
    //    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
