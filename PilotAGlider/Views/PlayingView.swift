//
//  PlayingView.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/16.
//

import SwiftUI

struct PlayingView: View {
    @Environment(AppModel.self) private var appModel
    @AppStorage(Constants.appStorageKeyOffset) var offset: Double = 0

    var body: some View {
        VStack {
            Text("Adjust the glider position")
            Slider(value: $offset, in: -0.5...1.0, step: 0.1)
                .onChange(of: offset) { _, newValue in
                    appModel.setBaseOffset(Float(newValue))
                }
                .padding(20)

            Button(action: {
                appModel.showingImmersiveSpace = false
            }, label: {
                Text("End")
                    .font(.callout)
            })
            .disabled(appModel.immersiveSpaceState != .open)
        } // VStack
        .frame(width: 200, height: 100)
    }
}

#Preview {
    PlayingView()
}
