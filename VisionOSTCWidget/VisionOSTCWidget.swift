//
//  VisionOSTCWidget.swift
//  VisionOSTCWidget
//
//  Created by Yugo Sugiyama on 2025/11/19.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), batteryLevel: "100%", memoryUsage: "45%", temperature: "22°C")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), batteryLevel: "100%", memoryUsage: "45%", temperature: "22°C")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // 現在時刻から1時間分のエントリを15分間隔で生成
        let currentDate = Date()
        for minuteOffset in 0 ..< 4 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset * 15, to: currentDate)!
            let entry = SimpleEntry(date: entryDate,
                                    batteryLevel: ["100%", "85%", "70%", "充電中"].randomElement()!,
                                    memoryUsage: ["45%", "52%", "48%", "60%"].randomElement()!,
                                    temperature: ["21°C", "22°C", "23°C", "24°C"].randomElement()!)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let batteryLevel: String
    let memoryUsage: String
    let temperature: String
}

struct WidgetView: View {
    var entry: SimpleEntry
    @Environment(\.levelOfDetail) var levelOfDetail: LevelOfDetail

    var body: some View {
        switch levelOfDetail {
        case .simplified:
            VStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("システム情報")
                    .font(.headline)
                    .fontWeight(.bold)
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        default:
            GeometryReader { proxy in
                let isLarge = proxy.size.width > 220
                VStack(spacing: 0) {
                    // ヘッダー
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("システム情報")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text(entry.date, style: .time)
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
                            Text(entry.date, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(entry.date, style: .time)
                                .font(.system(size: isLarge ? 48 : 36, weight: .bold, design: .rounded))
                        }
                        .padding(.vertical, 8)

                        Divider()

                        // システム情報グリッド
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                InfoRow(icon: "battery.100", label: "バッテリー", value: entry.batteryLevel, color: .green)
                                InfoRow(icon: "memorychip", label: "メモリ", value: entry.memoryUsage, color: .orange)
                            }
                            GridRow {
                                InfoRow(icon: "thermometer.medium", label: "温度", value: entry.temperature, color: .red)
                                InfoRow(icon: "wifi", label: "接続", value: "Wi-Fi", color: .blue)
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // 統計情報（ダミー）
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
                        Text("最終更新: " + entry.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                }
                .padding(.bottom, 2)
            }
        }
    }
}

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

struct VisionOSTCWidget: Widget {
    let kind: String = "VisionOSTCWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .supportedMountingStyles([.elevated])
        .configurationDisplayName("visionOS TC")
        .description("visionOS TC 2025のデモWidget")
        .widgetTexture(.paper)
    }
}

#Preview(as: .systemSmall) {
    VisionOSTCWidget()
} timeline: {
    SimpleEntry(date: .now, batteryLevel: "100%", memoryUsage: "45%", temperature: "22°C")
}

#Preview(as: .systemLarge) {
    VisionOSTCWidget()
} timeline: {
    SimpleEntry(date: .now, batteryLevel: "100%", memoryUsage: "45%", temperature: "22°C")
}

#Preview(as: .systemExtraLarge) {
    VisionOSTCWidget()
} timeline: {
    SimpleEntry(date: .now, batteryLevel: "100%", memoryUsage: "45%", temperature: "22°C")
}
