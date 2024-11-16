//
//  Constants.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/16.
//

import Foundation

enum Constants {
    // AppStorage Keys
    static let appStorageKeyOffset = "AppStorageKeyOffset"

    static let speedFactor: Float = 20.0
    static let gliderAltitudeMax: Float = 400.0 // [m]
    static let gliderAltitudeMin: Float = -200.0 // [m]
    static let gliderInitialAltitude: Float = 200 // [m]
    static let cloudAltitude: Float = 400.0 // [m]

    // Scenery
    static let sceneryShowingTime: Double = 30.0 // [sec]
    static let sceneryTransitionTime: Double = 3.0 // [sec]

    // Game Controller
    static let stickDeadZone: Float = 0.01
    static let stickPitchFactor: Float = 500.0
    static let stickYawFactor: Float = 500.0
    static let stickRollFactor: Float = 200.0
}
