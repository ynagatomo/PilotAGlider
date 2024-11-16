//
//  AppModel.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/15.
//

import SwiftUI
import RealityKit
import GameController
import OSLog

@MainActor
@Observable
class AppModel {
    var showingImmersiveSpace: Bool = false

    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    // Immersive Scene Game Loop

    private var accumulativeTime: Double = 0
    private var gliderEntity: Entity?
    private var skydomeEntity: Entity?

    private var gliderAltitude: Float = 0.0 // [m]
    private var gliderPitch = Float.zero
    private var gliderYaw = Float.zero
    private var gliderRoll: Float = 0 // [radians]

    // Game Controller

    var gameControllerConnected = false

    init() {
        setGameControllerNotification()
    }
}

// MARK: - Immersive Scene Animation

extension AppModel {
    func setupFlyingScene(_ rootEntity: Entity) {
        guard let glider = rootEntity.findEntity(named: "Glider"),
              let skydome = rootEntity.findEntity(named: "Skydome") else { return }

        self.gliderEntity = glider
        self.skydomeEntity = skydome

        self.accumulativeTime = 0
        gliderPitch = Float.zero
        gliderYaw = Float.zero
        gliderAltitude = Constants.gliderInitialAltitude // [m]
        gliderRoll = 0 // [radian]

        skydome.position = SIMD3<Float>(0, -Constants.gliderInitialAltitude, 0)
    }

    func gameLoop(_ deltaTime: Double) {
        accumulativeTime += deltaTime

        let gcvalue = pollGameControllerInput()
        gliderPitch += gcvalue.lyvalue / Constants.stickPitchFactor
        gliderYaw += gcvalue.lxvalue / Constants.stickYawFactor

        // [Note] Adding a roll can cause motion sickness. Be careful.
        // -----------------------------------------------------------
        // gliderRoll += gcvalue.lxvalue / Constants.stickRollFactor
        // gliderRoll = gliderRoll.clamped(min: -Float.pi / 3, max: Float.pi / 3)
        // if abs(gcvalue.lxvalue) < Constants.stickDeadZone {
        //    gliderRoll *= 0.99
        // }

        let quat = simd_quatf(angle: gliderPitch, axis: [1, 0, 0])
        * simd_quatf(angle: gliderYaw, axis: [0, 1, 0])
        // * simd_quatf(angle: gliderRoll, axis: [0, 0, 1])
        skydomeEntity?.orientation = quat

        let speed = expf(gcvalue.ryvalue + 1.0) * Constants.speedFactor // e^(0...2) => 1...e^2
        let velocityY = speed * -gliderPitch
        let movementY = velocityY * Float(deltaTime)
        if let skydomeEntity {
            let altitude = gliderAltitude + movementY
            if altitude < Constants.gliderAltitudeMax
                && altitude > Constants.gliderAltitudeMin {
                gliderAltitude = altitude
                skydomeEntity.position.y = -altitude
            }
        }
    }
}

// MARK: - Game Controller

extension AppModel {
    func setGameControllerNotification() {
        let center = NotificationCenter.default
        let main = OperationQueue.main

        center.addObserver(forName: NSNotification.Name.GCControllerDidConnect,
                           object: nil,
                           queue: main) { _ in
            Logger.appRunning.debug("** Game controller was connected.")
            Task { @MainActor in
                self.gameControllerConnected = true
                self.setupGCOnPressHandlers()
            }
        }

        center.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect,
                           object: nil,
                           queue: main) { _ in
            Logger.appRunning.debug("** Game controller was disconnected.")
            Task { @MainActor in
                self.gameControllerConnected = false
            }
        }
    }

    // swiftlint:disable:next large_tuple
    func pollGameControllerInput() -> (lxvalue: Float, lyvalue: Float, rxvalue: Float, ryvalue: Float) {
        var lxvalue: Float = 0
        var lyvalue: Float = 0
        var rxvalue: Float = 0
        var ryvalue: Float = 0

        if let gamecontroller = GCController.current {
            if let extendedGamepad = gamecontroller.extendedGamepad {
                lxvalue = extendedGamepad.leftThumbstick.xAxis.value // -1...1
                lyvalue = extendedGamepad.leftThumbstick.yAxis.value // -1...1
                rxvalue = extendedGamepad.rightThumbstick.xAxis.value // -1...1
                ryvalue = extendedGamepad.rightThumbstick.yAxis.value // -1...1
            }
        } else {
            // no game controller
        }

        return (lxvalue: lxvalue, lyvalue: lyvalue, rxvalue: rxvalue, ryvalue: ryvalue)
    }

    func setupGCOnPressHandlers() {
        // [B/O]
        registerGCOnPressedHander(input: GCInputButtonB) { [weak self] in
            self?.showingImmersiveSpace = true
        }
        // [A/X]
        registerGCOnPressedHander(input: GCInputButtonA) { [weak self] in
            self?.showingImmersiveSpace = false
        }
    }

    private func registerGCOnPressedHander(input: String, handler: @escaping () -> Void) {
        if let gamecontroller = GCController.current {
            gamecontroller.physicalInputProfile.buttons[input]?.valueChangedHandler
                = {  (_, _, pressed) in // (button, value, pressed)
                if pressed {
                    handler()
                }
            } // closure
        } // if
    } // func
}
