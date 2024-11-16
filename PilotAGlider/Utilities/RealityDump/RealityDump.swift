//
//  RealityDump.swift
//  PilotAGlider
//
//  Created by Yasuhito Nagatomo on 2024/11/16.
//

import Foundation
import RealityKit
import SwiftUI

#if DEBUG
// swiftlint:disable line_length
// swiftlint:disable file_length

private let keywords = [ // (string, indentLevel [1...])
    ("Entity", 1),
    ("ModelEntity", 1),
    ("AnchorEntity", 1),
    ("Components", 2),
    ("Unknown Component", 3),
    ("Transform Component", 3),
    ("Synchronization Component", 3),
    ("Anchoring Component", 3),
    ("Model Component", 3),
    ("Collision Component", 3),
    ("PhysicsBody Component", 3),
    ("PhysicsMotion Component", 3),
    ("CharacterController Component", 3),
    ("CharacterControllerState Component", 3),
    // [visionOS]
    ("AdaptiveResolutionComponent", 3),
    ("OpacityComponent", 3),
    ("VideoPlayerComponent", 3),
    ("ImageBasedLightComponent", 3),
    ("ImageBasedLightReceiverComponent", 3),
    ("ModelSortGroupComponent", 3),
    ("HoverEffectComponent", 3),
    ("PortalComponent", 3),
    ("WorldComponent", 3),
    ("InputTargetComponent", 3),
    ("TextComponent", 3),
    ("ViewAttachmentComponent", 3),
    ("AmbientAudioComponent", 3),
    ("AudioMixGroupsComponent", 3),
    ("ChannelAudioComponent", 3),
    ("SpatialAudioComponent", 3),
    ("PhysicsSimulationComponent", 3),
    ("ParticleEmitterComponent", 3)
]

/// Dump the RealityKit Entity object
/// - Parameters:
///   - entity: Entity or ModelEntity or AnchorEntity
///   - printing: if true, strings are printed to the console.
///   - detail: 0 = simple, 1 = detailed
///   - org: true = Emacs org mode
/// - Returns: dumped strings of the entity
@discardableResult
@MainActor func dumpRealityEntity(_ entity: Entity, printing: Bool = true, detail: Int = 1, org: Bool = true) -> [String] {
    var strings = [String]()
    if org {
        strings.append("-*- mode:org -*-")
    }

    strings += dumpEntity(entity, detail: detail, nesting: 0)

    let orgStrings: [String]
    if org {
        let maxLevel = (keywords.map { $0.1 }.max() ?? 0) + 1
        orgStrings = strings.map { string -> String in
            var orgPrefix = ""
            let hitKeywords = keywords.compactMap { keyword in
                string.contains(keyword.0) ? keyword : nil
            }
            if let keyword = hitKeywords.first {
                orgPrefix = String(repeating: "*", count: keyword.1) + String(repeating: " ",
                                                                              count: maxLevel - keyword.1)
            } else {
                orgPrefix = String(repeating: " ", count: maxLevel)
            }
            return orgPrefix + string
        }
    } else {
        orgStrings = strings
    }
    if printing {
        orgStrings.forEach { print($0) }
    }
    return orgStrings
}

@MainActor private func dumpEntity(_ entity: Entity, detail: Int, nesting: Int) -> [String] {
    let indentCharacterNumber = 2
    let strings = entityToStrings(entity, detail: detail, nesting: nesting)
    let nestedStrings = strings.map { string -> String in
        String(repeating: " ", count: nesting * indentCharacterNumber) + string
    }
    return nestedStrings
}

// swiftlint:disable function_body_length
@MainActor private func entityToStrings(_ entity: Entity, detail: Int, nesting: Int) -> [String] {
    var strings = [String]()
    let modelEntity = entity as? ModelEntity
    let anchorEntity = entity as? AnchorEntity

    if anchorEntity != nil {
        strings.append("<a> \(keywords[2].0)") // AnchorEntity
        #if !os(visionOS) // anchorIdentifier is not supported in visionOS
        if let anchorId = anchorEntity?.anchorIdentifier {
            strings.append("  +-- anchorIdentifier: \(anchorId)")
        }
        #endif
    } else if modelEntity != nil {
        strings.append("<M> \(keywords[1].0)") // ModelEntity
    } else {
        strings.append("<.> \(keywords[0].0)") // Entity
    }
    strings.append("  +-- name: \(entity.name)")
    strings.append("  +-- id (Uint64): \(entity.id)")
    strings.append("  +-- State")
    strings.append("  |     +-- isEnabled: \(entity.isEnabled)")
    strings.append("  |     +-- isEnabledInHierarchy: \(entity.isEnabledInHierarchy)")
    strings.append("  |     +-- isActive: \(entity.isActive)")
    strings.append("  |     +-- isAnchored: \(entity.isAnchored)")
    strings.append("  +-- Animation")
    strings.append("  |     +-- number of animations: \(entity.availableAnimations.count)")
    entity.availableAnimations.forEach { animation in
        strings.append("  |     +-- name: \(animation.name ?? "(none)")")
    }

    if let model = modelEntity {
        strings.append(    "  +-- Joint")
        strings.append(    "  |     +-- number of jointNames: \(model.jointNames.count)")
        model.jointNames.forEach { jointName in
            strings.append("  |     +-- jointName: \(jointName)")
        }
        strings.append(    "  |     +-- number of jointTransforms: \(model.jointTransforms.count)")
        model.jointTransforms.forEach { jointTransform in
            strings.append("  |     +-- jointTransform: \(jointTransform)")
        }
    }

    strings.append("  +-- Hierarhy")
    strings.append("  |     +-- has a parent: \(entity.parent == nil ? "No" : "Yes")")
    strings.append("  |     +-- number of children: \(entity.children.count)")
    strings.append("  +-- \(keywords[3].0)") // "Components"
    strings.append("  |     +-- number of components: \(entity.components.count)")
    if entity.components.count != 0 {
        strings += componentsToStrings(entity.components, detail: detail)
    }
    // dumpStrings.append("  +-- Description: \(entity.debugDescription)")
    strings.append("  +-------------------------------------------------")

    entity.children.forEach { child in
        strings += dumpEntity(child, detail: detail, nesting: nesting + 1)
    }

    return strings
}
// swiftlint:enable function_body_length

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
/// Transform component's value to strings
/// - Parameters:
///   - components: component set
///   - detail: detail level
/// - Returns: strings
///
/// - Warning: CharacterControllerComponent and CharacterControllerStateComponent are not be handled.
///            They are supported on iOS 15+.
@MainActor private func componentsToStrings(_ components: Entity.ComponentSet, detail: Int) -> [String] {
    let componentTypes: [Component.Type] = [
        Transform.self,
        SynchronizationComponent.self,
        AnchoringComponent.self,
        ModelComponent.self,
        CollisionComponent.self,
        PhysicsBodyComponent.self,
        PhysicsMotionComponent.self,
        CharacterControllerComponent.self,      // iOS 15.0+
        CharacterControllerStateComponent.self,  // iOS 15.0+
        AdaptiveResolutionComponent.self,
        OpacityComponent.self,
        VideoPlayerComponent.self,
        ImageBasedLightComponent.self,
        ImageBasedLightReceiverComponent.self,
        ModelSortGroupComponent.self,
        HoverEffectComponent.self,
        PortalComponent.self,
        WorldComponent.self,
        InputTargetComponent.self,
        TextComponent.self,
        ViewAttachmentComponent.self,
        AmbientAudioComponent.self,
        AudioMixGroupsComponent.self,
        ChannelAudioComponent.self,
        SpatialAudioComponent.self,
        PhysicsSimulationComponent.self,
        ParticleEmitterComponent.self
    ]
    var strings = [String]()

    componentTypes.forEach { type in
        if let component = components[type] {
            if let theComponent = component as? Transform {
                strings += transformComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? SynchronizationComponent {
                strings += syncComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? AnchoringComponent {
                strings += anchoringComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ModelComponent {
                strings += modelComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? CollisionComponent {
                strings += collisionComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? PhysicsBodyComponent {
                strings += physicsBodyComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? PhysicsMotionComponent {
                strings += physicsMotionComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? CharacterControllerComponent {  // iOS 15.0+
                strings += characterControllerComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? CharacterControllerStateComponent {  // iOS 15.0+
                strings += characterControllerStateComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? AdaptiveResolutionComponent {
                strings += adaptiveResolutionComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? OpacityComponent {
                strings += opacityComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? VideoPlayerComponent {
                strings += videoPlayerComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ImageBasedLightComponent {
                strings += imageBasedLightComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ImageBasedLightReceiverComponent {
                strings += imageBasedLightReceiverComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ModelSortGroupComponent {
                strings += modelSortGroupComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? HoverEffectComponent {
                strings += hoverEffectComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? PortalComponent {
                strings += portalComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? WorldComponent {
                strings += worldComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? InputTargetComponent {
                strings += inputTargetComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? TextComponent {
                strings += textComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ViewAttachmentComponent {
                strings += viewAttachmentComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? AmbientAudioComponent {
                strings += ambientAudioComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? AudioMixGroupsComponent {
                strings += audioMixGroupsComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ChannelAudioComponent {
                strings += channelAudioComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? SpatialAudioComponent {
                strings += spatialAudioComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? PhysicsSimulationComponent {
                strings += physicsSimulationComponentToStrings(theComponent, detail: detail)
            } else if let theComponent = component as? ParticleEmitterComponent {
                strings += particleEmitterComponentToStrings(theComponent, detail: detail)
            } else {
                strings.append("  |   ??  +-- \(component)")
            }
        }
    }
    if components.count > componentTypes.count {
        strings.append("  |     +-- \(keywords[4].0)") // "Unknown Component"
    }

    return strings
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length

@MainActor private func transformComponentToStrings(_ component: Transform, detail: Int) -> [String] {
    var strings = [String]()
    strings.append(    "  |     +-- \(keywords[5].0)") // Transform Component
    if detail > 0 {
        strings.append("  |     |     +-- scale: \(component.scale)")
        strings.append("  |     |     +-- rotation: \(component.rotation)")
        strings.append("  |     |     +-- translation: \(component.translation)")
        strings.append("  |     |     +-- matrix: \(component.matrix)")
    }
    return strings
}

@MainActor private func syncComponentToStrings(_ component: SynchronizationComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[6].0)") // Synchronization Component
    return strings
}

@MainActor private func anchoringComponentToStrings(_ component: AnchoringComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[7].0)") // "Anchoring Component"
    return strings
}

@MainActor private func modelComponentToStrings(_ component: ModelComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[8].0)") // "Model Component"
    if detail > 0 {
        if #available(iOS 15, *) {
            strings.append("  |     |     +-- bounding Box Margin: \(component.boundsMargin)")  // iOS 15.0+
        }
        strings.append("  |     |     +-- mesh")
        strings.append("  |     |     |    +-- expected Material Count: \(component.mesh.expectedMaterialCount)")
        strings.append("  |     |     |    +-- bounding Box - center: \(component.mesh.bounds.center)")
        if #available(iOS 15, *) {
            strings.append("  |     |     |    +-- resource - instances - count : \(component.mesh.contents.instances.count)") // iOS 15.0+
            strings.append("  |     |     |    +-- resource - models - count : \(component.mesh.contents.models.count)") // iOS 15.0+
        }
        strings.append("  |     |     +-- material")
        strings.append("  |     |     |    +-- number of materials: \(component.materials.count)")
        component.materials.forEach { material in
            strings.append("  |     |     |    +-- material: \(type(of: material))")
        }
    }
    return strings
}

@MainActor private func collisionComponentToStrings(_ component: CollisionComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[9].0)") // "Collision Component"
    if detail > 0 {
        strings.append("  |     |     +-- number of collision shapes: \(component.shapes.count)")
    }
    return strings
}

@MainActor private func physicsBodyComponentToStrings(_ component: PhysicsBodyComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[10].0)") // "PhysicsBody Component"
    if detail > 0 {
        strings.append("  |     |     +-- isContinuousCollisionDetectionEnabled: \(component.isContinuousCollisionDetectionEnabled)")
        strings.append("  |     |     +-- isRotationLocked: \(component.isRotationLocked)")
        strings.append("  |     |     +-- physics body mode: \(component.mode)")
        strings.append("  |     |     +-- mass [kg]: \(component.massProperties.mass)")
        strings.append("  |     |     +-- inertia [kg/m2]: \(component.massProperties.inertia)")
        strings.append("  |     |     +-- center of mass: \(component.massProperties.centerOfMass)")
    }
    return strings
}

@MainActor private func physicsMotionComponentToStrings(_ component: PhysicsMotionComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[11].0)") // "PhysicsMotion Component"
    if detail > 0 {
        strings.append("  |     |     +-- anglar velocity: \(component.angularVelocity)")
        strings.append("  |     |     +-- linear velocity: \(component.linearVelocity)")
    }
    return strings
}

@MainActor private func characterControllerComponentToStrings(_ component: CharacterControllerComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[12].0)") // "CharacterController Component"
    if detail > 0 {
        strings.append("  |     |     +-- (not be implemented.)")
    }
    return strings
}

@MainActor private func characterControllerStateComponentToStrings(_ component: CharacterControllerStateComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[13].0)") // "CharacterControllerState Component"
    if detail > 0 {
        strings.append("  |     |     +-- (not be implemented.)")
    }
    return strings
}

@MainActor private func adaptiveResolutionComponentToStrings(_ component: AdaptiveResolutionComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[14].0)")
    return strings
}

@MainActor private func opacityComponentToStrings(_ component: OpacityComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[15].0)")
    return strings
}

@MainActor private func videoPlayerComponentToStrings(_ component: VideoPlayerComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[16].0)")
    return strings
}

@MainActor private func imageBasedLightComponentToStrings(_ component: ImageBasedLightComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[17].0)")
    return strings
}

@MainActor private func imageBasedLightReceiverComponentToStrings(_ component: ImageBasedLightReceiverComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[18].0)")
    return strings
}

@MainActor private func modelSortGroupComponentToStrings(_ component: ModelSortGroupComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[19].0)")
    return strings
}

@MainActor private func hoverEffectComponentToStrings(_ component: HoverEffectComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[20].0)")
    return strings
}

@MainActor private func portalComponentToStrings(_ component: PortalComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[21].0)")
    return strings
}

@MainActor private func worldComponentToStrings(_ component: WorldComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[22].0)")
    return strings
}

@MainActor private func inputTargetComponentToStrings(_ component: InputTargetComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[23].0)")
    return strings
}

@MainActor private func textComponentToStrings(_ component: TextComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[24].0)")
    return strings
}

@MainActor private func viewAttachmentComponentToStrings(_ component: ViewAttachmentComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[25].0)")
    return strings
}

@MainActor private func ambientAudioComponentToStrings(_ component: AmbientAudioComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[26].0)")
    return strings
}

@MainActor private func audioMixGroupsComponentToStrings(_ component: AudioMixGroupsComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[27].0)")
    return strings
}

@MainActor private func channelAudioComponentToStrings(_ component: ChannelAudioComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[28].0)")
    return strings
}

@MainActor private func spatialAudioComponentToStrings(_ component: SpatialAudioComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[29].0)")
    return strings
}

@MainActor private func physicsSimulationComponentToStrings(_ component: PhysicsSimulationComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[30].0)")
    return strings
}

@MainActor private func particleEmitterComponentToStrings(_ component: ParticleEmitterComponent, detail: Int) -> [String] {
    var strings = [String]()
    strings.append("  |     +-- \(keywords[31].0)")
    return strings
}

#else
@discardableResult
@MainActor func dumpRealityEntity(_ entity: Entity, printing: Bool = true) -> [String] { return [] }
#endif
// swiftlint:enable line_length
