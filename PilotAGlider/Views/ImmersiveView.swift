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

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let rootEntity = try? await Entity(named: "Flight", in: realityKitContentBundle) {
                rootEntity.position = .init(x: 0, y: 0.7, z: 0)
                content.add(rootEntity)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
