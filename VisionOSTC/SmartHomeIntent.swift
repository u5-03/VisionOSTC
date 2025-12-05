//
//  SmartHomeIntent.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import Foundation
import AppIntents
import Observation

// MARK: - エアコン電源ON Intent
struct TurnOnAirConditionerIntent: AppIntent {
    static var title: LocalizedStringResource = "エアコンをつける"
    static var description = IntentDescription("エアコンの電源をONにします")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = "エアコンの電源をONにしました"
        print("🌡️ エアコン操作: 電源ON")

        SmartHomeManager.shared.recordAction(
            type: "エアコン",
            action: "turn_on",
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - エアコン電源OFF Intent
struct TurnOffAirConditionerIntent: AppIntent {
    static var title: LocalizedStringResource = "エアコンを消す"
    static var description = IntentDescription("エアコンの電源をOFFにします")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = "エアコンの電源をOFFにしました"
        print("🌡️ エアコン操作: 電源OFF")

        SmartHomeManager.shared.recordAction(
            type: "エアコン",
            action: "turn_off",
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - 温度を上げる Intent
struct IncreaseTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "温度を上げる"
    static var description = IntentDescription("エアコンの温度を上げます")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = "エアコンの温度を上げました"
        print("🌡️ エアコン操作: 温度上昇")

        SmartHomeManager.shared.recordAction(
            type: "エアコン",
            action: "temperature_up",
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - 温度を下げる Intent
struct DecreaseTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "温度を下げる"
    static var description = IntentDescription("エアコンの温度を下げます")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = "エアコンの温度を下げました"
        print("🌡️ エアコン操作: 温度下降")

        SmartHomeManager.shared.recordAction(
            type: "エアコン",
            action: "temperature_down",
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - 家族にメッセージを送る Intent
struct SendFamilyMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "家族にメッセージ"
    static var description = IntentDescription("家族にメッセージを送信します")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = "家族にメッセージを送信しました"
        print("📱 家族への連絡: メッセージ送信")

        SmartHomeManager.shared.recordAction(
            type: "家族連絡",
            action: "send_message",
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - 家族に電話する Intent
struct CallFamilyIntent: AppIntent {
    static var title: LocalizedStringResource = "家族に電話"
    static var description = IntentDescription("家族に電話をかけます")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = "家族に電話をかけます"
        print("📞 家族への連絡: 電話")

        SmartHomeManager.shared.recordAction(
            type: "家族連絡",
            action: "call_family",
            details: message
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - スマートホーム操作を管理するマネージャー
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

// MARK: - Siriショートカットのプロバイダー
struct SmartHomeShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        // エアコンをつける
        AppShortcut(
            intent: TurnOnAirConditionerIntent(),
            phrases: [
                "\(.applicationName)でエアコンをつけて",
                "\(.applicationName)でエアコンオン",
                "\(.applicationName)でエアコンの電源を入れて"
            ],
            shortTitle: "エアコンをつける",
            systemImageName: "power"
        )

        // エアコンを消す
        AppShortcut(
            intent: TurnOffAirConditionerIntent(),
            phrases: [
                "\(.applicationName)でエアコンを消して",
                "\(.applicationName)でエアコンオフ",
                "\(.applicationName)でエアコンの電源を切って"
            ],
            shortTitle: "エアコンを消す",
            systemImageName: "power"
        )

        // 温度を上げる
        AppShortcut(
            intent: IncreaseTemperatureIntent(),
            phrases: [
                "\(.applicationName)で温度を上げて",
                "\(.applicationName)で暖かくして",
                "\(.applicationName)でエアコンの温度を上げて"
            ],
            shortTitle: "温度を上げる",
            systemImageName: "thermometer.sun"
        )

        // 温度を下げる
        AppShortcut(
            intent: DecreaseTemperatureIntent(),
            phrases: [
                "\(.applicationName)で温度を下げて",
                "\(.applicationName)で涼しくして",
                "\(.applicationName)でエアコンの温度を下げて"
            ],
            shortTitle: "温度を下げる",
            systemImageName: "thermometer.snowflake"
        )

        // 家族にメッセージ
        AppShortcut(
            intent: SendFamilyMessageIntent(),
            phrases: [
                "\(.applicationName)で家族にメッセージを送って",
                "\(.applicationName)で家族に連絡して"
            ],
            shortTitle: "家族にメッセージ",
            systemImageName: "message"
        )

        // 家族に電話
        AppShortcut(
            intent: CallFamilyIntent(),
            phrases: [
                "\(.applicationName)で家族に電話して",
                "\(.applicationName)で家族に電話をかけて"
            ],
            shortTitle: "家族に電話",
            systemImageName: "phone"
        )
    }
}
