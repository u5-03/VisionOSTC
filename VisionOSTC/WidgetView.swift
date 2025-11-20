//
//  WidgetView.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import SwiftUI

/// visionOS用のWidget風UIコンポーネント
struct WidgetView: View {
    @State private var currentTime = Date()
    @State private var systemInfo = SystemInfo()

    struct SystemInfo {
        var batteryLevel: String = "充電中"
        var memoryUsage: String = "不明"
        var temperature: String = "22°C"
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("システム情報")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(currentTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))

            Divider()

            // コンテンツエリア
            VStack(spacing: 16) {
                // 時計表示
                VStack(spacing: 4) {
                    Text(currentTime, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currentTime, style: .time)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                }
                .padding(.vertical, 8)

                Divider()

                // システム情報グリッド
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                    GridRow {
                        InfoRow(icon: "battery.100", label: "バッテリー", value: systemInfo.batteryLevel, color: .green)
                        InfoRow(icon: "memorychip", label: "メモリ", value: systemInfo.memoryUsage, color: .orange)
                    }
                    GridRow {
                        InfoRow(icon: "thermometer.medium", label: "温度", value: systemInfo.temperature, color: .red)
                        InfoRow(icon: "wifi", label: "接続", value: "Wi-Fi", color: .blue)
                    }
                }
                .padding(.horizontal)

                Divider()

                // 統計情報
                HStack(spacing: 20) {
                    StatCard(title: "通知", value: "3", icon: "bell.fill", color: .purple)
                    StatCard(title: "メッセージ", value: "12", icon: "message.fill", color: .green)
                    StatCard(title: "タスク", value: "5", icon: "checkmark.circle.fill", color: .blue)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)

            Divider()

            // フッター
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("visionOS 2.6 Widget")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("最終更新: \(currentTime, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
        }
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
        .onAppear {
            startTimer()
        }
    }

    private func startTimer() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                currentTime = Date()
                updateSystemInfo()
            }
        }
    }

    private func updateSystemInfo() {
        // システム情報を更新（ダミーデータ）
        let batteryLevels = ["100%", "85%", "70%", "充電中"]
        let memoryUsages = ["45%", "52%", "48%", "60%"]
        let temperatures = ["21°C", "22°C", "23°C", "24°C"]

        systemInfo.batteryLevel = batteryLevels.randomElement() ?? "不明"
        systemInfo.memoryUsage = memoryUsages.randomElement() ?? "不明"
        systemInfo.temperature = temperatures.randomElement() ?? "不明"
    }
}

/// 情報行コンポーネント
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
}

/// 統計カードコンポーネント
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview(windowStyle: .automatic) {
    WidgetView()
        .frame(width: 500, height: 600)
}
