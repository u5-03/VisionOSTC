//
//  SmartHomeIntent.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import Foundation
import AppIntents
import Observation

// Wake wordの定数
let WAKE_WORD = "sugiy"

// エアコン操作の種類を定義
enum AirConditionerAction: String, AppEnum {
    case increaseTemperature = "temperature_up"
    case decreaseTemperature = "temperature_down"
    case turnOn = "turn_on"
    case turnOff = "turn_off"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "エアコン操作"

    static var caseDisplayRepresentations: [AirConditionerAction: DisplayRepresentation] = [
        .increaseTemperature: "温度を上げる",
        .decreaseTemperature: "温度を下げる",
        .turnOn: "電源ON",
        .turnOff: "電源OFF"
    ]
}

// 家族への連絡種類を定義
enum FamilyContactAction: String, AppEnum {
    case sendMessage = "send_message"
    case callFamily = "call_family"
    case shareLocation = "share_location"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "家族への連絡"

    static var caseDisplayRepresentations: [FamilyContactAction: DisplayRepresentation] = [
        .sendMessage: "メッセージを送る",
        .callFamily: "電話をかける",
        .shareLocation: "位置情報を共有"
    ]
}

// エアコン操作用のApp Intent
struct AirConditionerControlIntent: AppIntent {
    static var title: LocalizedStringResource = "エアコン操作"
    static var description = IntentDescription("エアコンを操作します")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "操作内容", default: .turnOn)
    var action: AirConditionerAction

    @Parameter(title: "温度変更量", default: 1)
    var temperatureChange: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$action)を実行") {
            \.$temperatureChange
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message: String

        switch action {
        case .increaseTemperature:
            let temp = temperatureChange ?? 1
            message = "エアコンの温度を\(temp)度上げます"
            print("🌡️ エアコン操作: 温度を\(temp)度上昇")
            // ダミー実装: 実際のAPI呼び出しはここで行う

        case .decreaseTemperature:
            let temp = temperatureChange ?? 1
            message = "エアコンの温度を\(temp)度下げます"
            print("🌡️ エアコン操作: 温度を\(temp)度下降")

        case .turnOn:
            message = "エアコンの電源をONにします"
            print("🌡️ エアコン操作: 電源ON")

        case .turnOff:
            message = "エアコンの電源をOFFにします"
            print("🌡️ エアコン操作: 電源OFF")
        }

        SmartHomeManager.shared.recordAction(
            type: "エアコン",
            action: action.rawValue,
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// 家族への連絡用のApp Intent
struct FamilyContactIntent: AppIntent {
    static var title: LocalizedStringResource = "家族への連絡"
    static var description = IntentDescription("家族に連絡します")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "連絡方法", default: .sendMessage)
    var action: FamilyContactAction

    @Parameter(title: "メッセージ内容", default: "連絡します")
    var message: String?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$action)を実行") {
            \.$message
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let responseMessage: String

        switch action {
        case .sendMessage:
            let msg = message ?? "メッセージ"
            responseMessage = "家族に「\(msg)」を送信します"
            print("📱 家族への連絡: メッセージ送信 - \(msg)")
            // ダミー実装: 実際のメッセージ送信はここで行う

        case .callFamily:
            responseMessage = "家族に電話をかけます"
            print("📞 家族への連絡: 電話をかける")

        case .shareLocation:
            responseMessage = "家族に位置情報を共有します"
            print("📍 家族への連絡: 位置情報を共有")
        }

        SmartHomeManager.shared.recordAction(
            type: "家族連絡",
            action: action.rawValue,
            details: responseMessage
        )

        return .result(dialog: IntentDialog(stringLiteral: responseMessage))
    }
}

// スマートホーム操作を管理するマネージャー
@MainActor
@Observable
class SmartHomeManager {
    static let shared = SmartHomeManager()

    var lastAction: String = "未実行"
    var actionHistory: [ActionRecord] = []

    struct ActionRecord: Identifiable, Hashable {
        let id = UUID()
        let timestamp: String
        let type: String
        let action: String
        let details: String

        var displayText: String {
            "[\(timestamp)] \(type): \(details)"
        }
    }

    private init() {}

    func recordAction(type: String, action: String, details: String) {
        let timestamp = Date().formatted(date: .abbreviated, time: .standard)
        let record = ActionRecord(
            timestamp: timestamp,
            type: type,
            action: action,
            details: details
        )

        lastAction = record.displayText
        actionHistory.insert(record, at: 0)

        // 履歴は最新20件まで保持
        if actionHistory.count > 20 {
            actionHistory.removeLast()
        }

        print("📝 操作記録: \(record.displayText)")
    }
}

// Siriショートカットのプロバイダー
struct SmartHomeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AirConditionerControlIntent(),
            phrases: [
                "\(.applicationName)でエアコン操作",
                "\(.applicationName)で温度調整",
                "\(.applicationName)でエアコンつけて",
                "\(.applicationName)でエアコン消して"
            ],
            shortTitle: "エアコン操作",
            systemImageName: "air.conditioner.vertical"
        )
    }
}
