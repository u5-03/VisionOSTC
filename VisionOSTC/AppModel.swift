//
//  AppModel.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    // Portal制御
    var shouldShowPortal = false

    // Portal位置（メートル単位）
    var portalPosition: SIMD3<Float> = [0, 1.5, -2.0]  // 目の高さ、2m前方

    // Portalサイズ（メートル単位）
    var portalSize: Float = 1.0
}
