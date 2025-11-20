//
//  NotificationManager.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var isAuthorized = false

    private override init() {
        super.init()
        // デリゲートを設定してフォアグラウンド通知を表示できるようにする
        UNUserNotificationCenter.current().delegate = self
    }

    // フォアグラウンドで通知を表示するためのデリゲートメソッド
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // visionOSではbanner形式で通知を表示
        return [.banner, .sound]
    }

    /// 通知の権限をリクエスト
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                print("通知の権限が許可されました")
            } else {
                print("通知の権限が拒否されました")
            }
        } catch {
            print("通知権限のリクエストに失敗しました: \(error.localizedDescription)")
        }
    }

    /// ローカル通知を送信
    func sendLocalNotification(title: String, body: String) async {
        // 権限チェック
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("通知が許可されていません")
            await requestAuthorization()
            return
        }

        // 通知コンテンツの作成
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // トリガーの設定（即座に表示）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // リクエストの作成
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        // 通知を登録
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("通知を送信しました: \(content.title)")
        } catch {
            print("通知の送信に失敗しました: \(error.localizedDescription)")
        }
    }
}
