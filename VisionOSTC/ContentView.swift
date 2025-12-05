//
//  ContentView.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum DemoItem: String, CaseIterable, Identifiable {
    case widget = "Widget表示"
    case portal = "Portal (景色表示)"
    case notification = "ローカル通知"
    case smartHomeHistory = "スマートホーム操作履歴"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .widget:
            return "square.grid.2x2.fill"
        case .portal:
            return "visionpro.fill"
        case .notification:
            return "bell.fill"
        case .smartHomeHistory:
            return "list.bullet.clipboard.fill"
        }
    }

    var description: String {
        switch self {
        case .widget:
            return "visionOS 2.6のWidget風UIで任意の情報を表示"
        case .portal:
            return "Portalで景色を表示（位置・サイズ調整可能）"
        case .notification:
            return "ローカルプッシュ通知を送信"
        case .smartHomeHistory:
            return "Siriショートカット操作履歴を表示"
        }
    }
}

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    @State private var notificationManager = NotificationManager.shared
    @State private var smartHomeManager = SmartHomeManager.shared

    @State private var selectedDemo: DemoItem?

    var body: some View {
        NavigationSplitView {
            // サイドバー: デモ一覧
            List(DemoItem.allCases, selection: $selectedDemo) { item in
                NavigationLink(value: item) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.rawValue)
                                .font(.headline)
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: item.icon)
                            .foregroundStyle(.blue)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("visionOS TC デモ")
        } detail: {
            // 詳細ビュー: 選択されたデモの表示
            if let demo = selectedDemo {
                detailView(for: demo)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "visionpro")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    Text("visionOS TC 2025")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("左のリストからデモを選択してください")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.vertical)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("実装内容:")
                            .font(.headline)
                        ForEach(DemoItem.allCases) { item in
                            HStack {
                                Image(systemName: item.icon)
                                    .foregroundStyle(.blue)
                                Text(item.rawValue)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Siriショートカットは「Hey Siri, ビジョンでエアコンをつけて」などで利用できます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
        }
        .task {
            // アプリ起動時に通知権限をリクエスト
            await notificationManager.requestAuthorization()
        }
    }

    @ViewBuilder
    private func detailView(for demo: DemoItem) -> some View {
        switch demo {
        case .widget:
            WidgetView()
                .padding()

        case .portal:
            PortalControlView()

        case .notification:
            VStack(spacing: 20) {
                Text("ローカル通知デモ")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("ローカルプッシュ通知を送信します")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(spacing: 16) {
                    if notificationManager.isAuthorized {
                        Label("通知権限: 許可済み", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("通知権限: 未許可", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }

                    Button(action: {
                        Task {
                            await notificationManager.sendLocalNotification(
                                title: "visionOS TC 通知",
                                body: "これはローカル通知のテストです!"
                            )
                        }
                    }) {
                        Label("通知を送信", systemImage: "bell.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()

        case .smartHomeHistory:
            VStack(spacing: 20) {
                Text("スマートホーム操作履歴")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Siriショートカットの実行履歴")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Siriで試してみよう:")
                        .font(.headline)
                    Text("「Hey Siri, ビジョンでエアコンをつけて」")
                    Text("「Hey Siri, ビジョンで温度を上げて」")
                    Text("「Hey Siri, ビジョンで家族に連絡して」")
                }
                .font(.subheadline)
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if smartHomeManager.actionHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("まだ操作履歴がありません")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Siriで上記のフレーズを試してみてください")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(smartHomeManager.actionHistory) { record in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: record.type == "エアコン" ? "air.conditioner.vertical" : "person.2.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 30)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.type)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(record.details)
                                            .font(.subheadline)
                                        Text(record.timestamp)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
    }
}

/// Immersive Spaceの開閉ボタン
struct ToggleImmersiveSpaceButton: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        Button {
            Task {
                switch appModel.immersiveSpaceState {
                case .open:
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    appModel.immersiveSpaceState = .closed

                case .closed:
                    appModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                    case .opened:
                        appModel.immersiveSpaceState = .open
                    case .error, .userCancelled:
                        appModel.immersiveSpaceState = .closed
                    @unknown default:
                        appModel.immersiveSpaceState = .closed
                    }
                case .inTransition:
                    break
                }
            }
        } label: {
            Label(
                appModel.immersiveSpaceState == .open ? "Immersive Spaceを閉じる" : "Immersive Spaceを開く",
                systemImage: appModel.immersiveSpaceState == .open ? "xmark.circle.fill" : "visionpro.fill"
            )
            .font(.title3)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(appModel.immersiveSpaceState == .inTransition)
    }
}

/// Portal制御ビュー
struct PortalControlView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    @State private var isPortalWindowOpen = false

    var body: some View {
        @Bindable var appModel = appModel

        ScrollView {
            VStack(spacing: 20) {
                Text("Portal デモ")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Portalウィンドウを開いて景色を見る")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Divider()

                // Portal Window制御
                VStack(spacing: 16) {
                    Text("Portal Window")
                        .font(.headline)

                    Button {
                        if isPortalWindowOpen {
                            dismissWindow(id: "PortalWindow")
                            isPortalWindowOpen = false
                        } else {
                            openWindow(id: "PortalWindow")
                            isPortalWindowOpen = true
                        }
                    } label: {
                        Label(
                            isPortalWindowOpen ? "Portal Windowを閉じる" : "Portal Windowを開く",
                            systemImage: isPortalWindowOpen ? "xmark.circle.fill" : "macwindow.badge.plus"
                        )
                        .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 使い方の説明
                VStack(alignment: .leading, spacing: 12) {
                    Text("使い方:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("ボタンでPortal Windowを開く", systemImage: "1.circle.fill")
                        Label("Windowをドラッグして移動", systemImage: "2.circle.fill")
                        Label("Windowの角をドラッグしてサイズ調整", systemImage: "3.circle.fill")
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
