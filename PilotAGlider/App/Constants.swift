//
//  Constants.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/16.
//

import Foundation

enum Constants {
    static let speedFactor: Float = 20.0
    static let gliderAltitudeMax: Float = 400.0 // [m]
    static let gliderAltitudeMin: Float = -200.0 // [m]
    static let gliderInitialAltitude: Float = 200 // [m]

    // Game Controller
    static let stickDeadZone: Float = 0.01
    static let stickPitchFactor: Float = 500.0
    static let stickYawFactor: Float = 500.0
    static let stickRollFactor: Float = 200.0
}
