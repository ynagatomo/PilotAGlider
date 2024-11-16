//
//  ContentView.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/15.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        if appModel.immersiveSpaceState == .closed {
            StartView()
        } else {
            EmptyView()
                .frame(width: 10, height: 10)
            // PlayingView()  // Use this View if you want to close by tapping
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
